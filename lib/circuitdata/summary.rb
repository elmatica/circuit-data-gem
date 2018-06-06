require 'bigdecimal'
module Circuitdata
  class Summary

    SUMMARY_FIELDS = {
      general: [
        :base_materials,
        :number_of_conductive_layers,
        :minimum_track,
        :minimum_spacing,
        :final_finish,
        :base_copper_thickness
      ],
      panel: [
        :board_outline,
        :final_thickness,
        :panel_size,
        :pcbs_in_array
      ],
      standards:[],
      packaging: [],
      holes: [
        :number_of_holes,
        :holes_density,
        :min_annular_ring,
        :min_through_hole_size,
        :max_aspect_ratio # thickness/min_hole_size
      ],
      solder_mask: [
        :solder_mask_sides,
        :solder_mask_materials,
        :solder_mask_finish,
        :solder_mask_colors
      ],
      legend: [
        :legend_materials # list materials if present
      ]
    }

    def initialize(product)
      @product = product
    end

    def data
      d = {}
      SUMMARY_FIELDS.each do |key, section|
        d[key] = {}
        section.each do |node|
          if self.respond_to?(node, true)
            # Only add value it  != nil
            if method(node).call
              d[key][node] = method(node).call
            end
          end
        end
      end
      d
    end

    private

    # helper functions
    def conductive_layers
      @product.layers.select{ |layer| layer[:function] == "conductive"}
    end

    def board_area
      # if size is present, use that
      if @product.metrics.key?(:array)
        if @product.metrics[:array].key?(:size_x)
          if @product.metrics[:array].key?(:size_y)
            return @product.metrics[:array][:size_x]*@product.metrics[:array][:size_y]
          end
        end
      end
      # try adding up all sections
      sizes = @product.sections.map{|section| section[:mm2]}
      sizes.inject(:+)
    end
    # mapping
    def base_materials
      #puts @product.pretty_inspect
      materials = @product.sections.map{ |section| section[:name]}
      if materials.length > 0
        return materials
      end
    end

    # Return number of conductive layers
    def number_of_conductive_layers
      if conductive_layers.length > 0
        return conductive_layers.length
      end
    end

    def minimum_track
      min = 1000
      conductive_layers.each do |layer|
        if layer.key?(:layer_attributes)
          if layer[:layer_attributes].key?(:minimum_track_width)
            min = [min, layer[:layer_attributes][:minimum_track_width]].min
          end
        end
      end
      return min unless min == 1000
    end

    def minimum_spacing
      min = 1000
      conductive_layers.each do |layer|
        if layer.key?(:layer_attributes)
          if layer[:layer_attributes].key?(:minimum_spacing_width)
            min = [min, layer[:layer_attributes][:minimum_spacing_width]].min
          end
        end
      end
      return min unless min == 1000
    end

    def final_finish
      materials = @product.layers.select{ |layer| layer[:function] == "final_finish"}.map{|layer| layer[:materials]}
      if materials.length > 0
        return materials.first.first
      end
    end

    def base_copper_thickness
      conductive_layers.map{|layer| layer[:thickness]}.first
    end

    def board_outline
      if @product.metrics.key?(:board)
        if @product.metrics[:board].key?(:size_x)
          if @product.metrics[:board].key?(:size_y)
            return @product.metrics[:board][:size_x].to_s+" x "+@product.metrics[:board][:size_y].to_s+" mm"
          end
        end
      end
    end

    def final_thickness
      if @product.metrics.key?(:board)
        if @product.metrics[:board].key?(:thickness)
          return @product.metrics[:board][:thickness]
        end
      end
    end

    def panel_size
      if @product.metrics.key?(:array)
        if @product.metrics[:array].key?(:size_x)
          if @product.metrics[:array].key?(:size_y)
            x = BigDecimal(@product.metrics[:array][:size_x].to_s)
            y = BigDecimal(@product.metrics[:array][:size_y].to_s)
            return x.truncate(1).to_s+" x "+y.truncate(1).to_s+" mm"
          end
        end
      end
    end

    def pcbs_in_array
      if @product.metrics.key?(:array)
        if @product.metrics[:array].key?(:boards_x)
          if @product.metrics[:array].key?(:boards_y)
            return @product.metrics[:array][:boards_x]*@product.metrics[:array][:boards_y]
          end
        end
      end
    end

    def number_of_holes
      @product.processes.map{ |process| process[:function_attributes][:number_of_holes]}.inject(:+)
    end

    def holes_density
      if !board_area.nil?
        if !number_of_holes.nil?
          dm2 = board_area/10000.0
          return BigDecimal(number_of_holes.to_d/dm2.to_f).truncate(1).to_s.to_f
        end
      end
    end

    def min_annular_ring
      @product.processes.map{ |process| process[:function_attributes][:minimum_designed_annular_ring]}.compact.min
    end

    def min_through_hole_size
      @product.processes.map{ |process| process[:function_attributes][:finished_size]}.min
    end

    def max_aspect_ratio
      if final_thickness
        if min_through_hole_size
          th = BigDecimal(min_through_hole_size.to_s)/1000.0
          ft = BigDecimal(final_thickness.to_s)
          return (ft/th).truncate(2).to_s.to_f
        end
      end
    end

    def solder_mask_sides
      nr_masks = @product.layers.select{ |layer| layer[:function] == "soldermask"}.length
      return "One side" if nr_masks == 1
      return "Both" if nr_masks == 2
      "None"
    end

    def solder_mask_materials
      layers = @product.layers.select{ |layer| layer[:function] == "soldermask"}
      materials = layers.map{|layer| layer[:materials]}.flatten.uniq
      return materials if materials.length > 0
    end

    def solder_mask_finish
      layer = @product.layers.select{ |layer| layer[:function] == "soldermask"}.first
      if !layer.nil?
        material_name = layer[:materials].first
        material = @product.materials_data[material_name.to_sym]
        if !material.nil?
          if material.key?(:attributes)
            return material[:attributes][:finish]
          end
        end
      end
    end

    def solder_mask_colors
      masks =  @product.layers.select{ |layer| layer[:function] == "soldermask"}
      colors = []
      masks.each do |mask|
        if mask.key?(:layer_attributes)
          colors << mask[:layer_attributes][:color]
        end
      end
      return colors.uniq if colors.length > 0
    end

    def legend_materials
      materials = @product.layers.select{ |layer| layer[:function] == "legend"}.map{ |material| material[:materials][0]}
      if materials.length > 0
        return materials.uniq
      end
    end
  end
end
