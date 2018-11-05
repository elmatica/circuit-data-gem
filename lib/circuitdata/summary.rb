require 'bigdecimal'
module Circuitdata
  class Summary

    SUMMARY_FIELDS = [
        :base_materials,
        :number_of_conductive_layers,
        :board_outline,
        :final_thickness,
        :minimum_track,
        :minimum_spacing,
        :min_through_hole_size,
        :max_aspect_ratio
    ]

    def initialize(product)
      @product = product
    end

    def data
      d = {}
      SUMMARY_FIELDS.each do |key|
        value = send(key)
        # Only add value if != nil
        if value.nil?
          d[key] = "unknown"
        else
          d[key] = value
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

    def board_outline
      array = @product.metrics.fetch(:board, {})
      size_x = array[:size_x]
      size_y = array[:size_y]
      return size_x.to_s+" x "+size_y.to_s+" mm" if size_x && size_y
    end

    def final_thickness
      @product.metrics.dig(:board, :thickness)
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
  end
end
