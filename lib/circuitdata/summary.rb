
module Circuitdata
  class Summary

    SUMMARY_FIELDS = {
      general: [
        :base_materials,
        :number_of_conductive_layers,
        :minimum_track,
        :minimum_gap,
        :final_finish,
        :base_copper_thickness
      ],
      panel: [
        :board_outline,
        :final_thickness,
        :panel_size,
        :pcbs_in_panel
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
        :finish,
        :color
      ],
      materials: [], # list material types if present
      legend: [
        :materials # list materials if present
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

    def conductive_layers
      @product.layers.select{ |layer| layer[:function] == "conductive"}
    end

    def base_materials
      materials = @product.materials_data.map{ |key, material| material[:name]}
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
    end

    def minimum_gap
    end

    def final_finish
    end

    def base_copper_thickness
    end

    def board_outline
    end

    def final_thickness
    end

    def panel_size
    end

    def pcbs_in_panel
    end

    def number_of_holes
      @product.processes.map{ |process| process[:function_attributes][:number_of_holes]}.inject(:+)
    end

    def holes_density
    end

    def min_annular_ring
    end

    def min_through_hole_size
      @product.processes.map{ |process| process[:function_attributes][:finished_size]}.min
    end

    def min_aspect_ratio
    end

    def solder_mask_sides
    end

    def solder_mask_materials
    end

    def finish
    end

    def color
    end

    def materials
      materials = @product.layers.select{ |layer| layer[:function] == "legend"}.map{ |material| material[:materials][0]}
      if materials.length > 0
        return materials
      end
    end
  end
end
