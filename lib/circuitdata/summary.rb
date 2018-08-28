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
          value = send(node)
          # Only add value if != nil
          unless value.nil?
            d[key][node] = value
          end
        end
      end
      d
    end

    private

    # helper functions
    def conductive_layers
      layers_with_function("conductive")
    end

    def board_area
      # try adding up all sections
      sizes = @product.sections.map{|section| section[:mm2]}
      sizes.compact.inject(0, :+)
    end

    def layers_with_function(func)
      @product.layers.select{ |layer| layer[:function] == func}
    end

    # mapping
    def base_materials
      dielectrics = layers_with_function("dielectric")
      return nil if dielectrics.length == 0
      flexes = dielectrics.map{|d| d.dig(:flexible)}.compact.uniq
      return "Flexible" if flexes === [true]
      return "Rigid" if flexes === [false]
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
      conductive_layers.map { |layer| layer.dig(:layer_attributes, :minimum_track_width)}.compact.min
    end

    def minimum_spacing
      conductive_layers.map { |layer| layer.dig(:layer_attributes, :minimum_spacing_width)}.compact.min
    end

    def final_finishes
      materials = layers_with_function("final_finish").flat_map { |layer| layer[:materials] }.compact
      if materials.length > 0
        return materials.uniq
      end
    end

    def base_copper_thickness
      conductive_layers.map{|layer| layer[:thickness]}.first
    end

    def board_outline
      array = @product.metrics.fetch(:board, {})
      size_x = array[:size_x]
      size_y = array[:size_y]
      return size_x.to_s+" x "+size_y.to_s+" mm" if size_x && size_y
    end

    def final_thickness
      @product.metrics.dig(:board, :thickness)
    end

    def panel_size
      array = @product.metrics.fetch(:array, {})
      size_x = array[:size_x]
      size_y = array[:size_y]
      if size_x && size_y
        x = BigDecimal(size_x.to_s)
        y = BigDecimal(size_y.to_s)
        return x.truncate(1).to_s+" x "+y.truncate(1).to_s+" mm"
      end
    end

    def pcbs_in_array
      array = @product.metrics.fetch(:array, {})
      boards_x = array[:boards_x]
      boards_y = array[:boards_y]
      return boards_x*boards_y if boards_x && boards_y
    end

    def number_of_holes
      @product.processes.map { |process| process.dig(:function_attributes, :number_of_holes) }.compact.inject(:+)
    end

    def holes_density
      if !board_area.nil? && !number_of_holes.nil?
        dm2 = board_area / 10000.0
        return BigDecimal(number_of_holes.to_d / dm2.to_f).truncate(1).to_s.to_f
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
      nr_masks = layers_with_function("soldermask").length
      return "One side" if nr_masks == 1
      return "Both" if nr_masks == 2
      return "None" if @product.layers.length > 0
    end

    def solder_mask_materials
      layers = layers_with_function("soldermask")
      materials = layers.flat_map { |layer| layer[:materials] }.compact.uniq
      return materials if materials.length > 0
    end

    def solder_mask_finishes
      soldermasks = layers_with_function("soldermask")
      finishes = soldermasks.map do |layer|
        material_name = layer.dig(:materials, 0)
        next if material_name.nil?
        material = @product.materials_data[material_name.to_sym]
        if !material.nil?
          material.dig(:attributes, :finish)
        end
      end.compact.uniq
      return finishes if finishes.length > 0
    end

    def solder_mask_colors
      masks =  layers_with_function("soldermask")
      colors = []
      masks.each do |mask|
        if mask.key?(:layer_attributes)
          colors << mask[:layer_attributes][:color]
        end
      end
      return colors.uniq if colors.length > 0
    end

    def legend_materials
      materials = layers_with_function("legend")
        .map { |material| material.dig(:materials, 0) }
        .compact
      if materials.length > 0
        return materials.uniq
      end
    end
  end
end
