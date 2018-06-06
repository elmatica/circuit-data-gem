require 'bigdecimal'
module Circuitdata
  class Summary

    SUMMARY_FIELDS = {
      general: [
        :base_materials,
        :number_of_conductive_layers,
        :minimum_track,
        :minimum_spacing,
        :final_finishes,
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
        :solder_mask_finishes,
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
          # Only add value it  != nil
          if method(node).call
            d[key][node] = send(node)
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
      # try adding up all sections
      sizes = @product.sections.map{|section| section[:mm2]}
      sizes.sum(nil)
    end

    # mapping
    def base_materials
      dielectrics = @product.layers.select{ |layer| layer[:function] == "dielectric"}
      return nil if dielectrics.length == 0
      flexes = dielectrics.map{|d| d.dig(:flexible)}.compact.uniq
      return "Flexible" if flexes.length == 1 && flexes.first == true
      return "Rigid" if flexes.length == 1 && flexes.first == false
      return "Rigid Flex" if flexes.length == 2
      return "Unknown" # dielectric is present, but does not have flex info.
    end

    # Return number of conductive layers
    def number_of_conductive_layers
      if conductive_layers.length > 0
        return conductive_layers.length
      end
    end

    def minimum_track
      conductive_layers.map { |layer| layer[:layer_attributes][:minimum_track_width] if layer.key?(:layer_attributes)}.compact.min
    end

    def minimum_spacing
      conductive_layers.map { |layer| layer[:layer_attributes][:minimum_spacing_width] if layer.key?(:layer_attributes)}.compact.min
    end

    def final_finishes
      materials = @product.layers.select{ |layer| layer[:function] == "final_finish"}.flat_map{|layer| layer[:materials]}
      if materials.length > 0
        return materials.uniq
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
      #@product.processes.dig(:function_attributes, :number_of_holes).compact.inject(:+)
      @product.processes.map{ |process| process.dig(:function_attributes, :number_of_holes)}.compact.inject(:+)
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
      @product.processes.map{ |process| process.dig(:function_attributes, :minimum_designed_annular_ring)}.compact.min
    end

    def min_through_hole_size
      @product.processes.map{ |process| process.dig(:function_attributes,:finished_size)}.compact.min
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
      return "None" if @product.layers.length > 0
    end

    def solder_mask_materials
      layers = @product.layers.select{ |layer| layer[:function] == "soldermask"}
      materials = layers.map{|layer| layer[:materials]}.flatten.uniq
      return materials if materials.length > 0
    end

    def solder_mask_finishes
      soldermasks = @product.layers.select{ |layer| layer[:function] == "soldermask"}
      finishes = soldermasks.map do |layer|
        material_name = layer[:materials].first
        material = @product.materials_data[material_name.to_sym]
        if !material.nil?
          if material.key?(:attributes)
            material[:attributes][:finish]
          end
        end
      end
      return finishes.compact.uniq if finishes.compact.length > 0
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
