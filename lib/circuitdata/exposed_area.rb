module Circuitdata
  class ExposedArea

    def initialize(product)
      @product = product
    end

    def exposed_copper_area
      return nil if board_area.nil?
      exposed_layer_copper_area+barrel_area
    end

    def barrel_area
      return 0 if board_thickness.nil?
      plated_through_holes.map{ |hole|  sum_holes_area(hole)}.sum
    end

    private

    def exposed_layer_copper_area
      coverage = []
      unless top_final_finish.nil?
        if top_final_finish[:coverage].is_a? Numeric
          coverage << top_final_finish[:coverage]
        end
      end
      unless bottom_final_finish.nil?
        if bottom_final_finish[:coverage].is_a? Numeric
          coverage << bottom_final_finish[:coverage]
        end
      end
      coverage.map{ |percent| percent/100.0*board_area}.sum
    end

    def sum_holes_area(hole)
      diameter = hole[:function_attributes][:finished_size]
      number_of_holes = hole[:function_attributes][:number_of_holes]
      hole_area(diameter)*number_of_holes
    end

    def hole_area(finished_size)
      (finished_size/1000)*Math::PI*board_thickness
    end

    def board_thickness
      @product.question_answer([:metrics, :board, :thickness])
    end

    def board_area
      @product.question_answer([:metrics, :board, :area])
    end

    def plated_through_holes
      @product.processes
        .select{|process| process[:function] == "holes"}
        .select{|process| process[:function_attributes][:plated] == true}
        .select{|process| process[:function_attributes][:hole_type] == "through"}
        .select{|process| process[:function_attributes][:number_of_holes].present?}
        .select{|process| process[:function_attributes][:finished_size].present?}
    end

    def layers
      @product.layers
    end

    def top_final_finish
      return nil if conductive_final_finish_layers.first.nil?
      return nil if conductive_final_finish_layers.first[:function] != "final_finish"
      conductive_final_finish_layers.first
    end

    def bottom_final_finish
      return nil if conductive_final_finish_layers.last.nil?
      return nil if conductive_final_finish_layers.last[:function] != "final_finish"
      conductive_final_finish_layers.last
    end

    # We are using the knowledge that at least one conductive layer must
    # be present to separate the top and bottom solder masks from each other.
    def conductive_final_finish_layers
      layers.select{ |layer| ["conductive", "final_finish"].include?(layer[:function]) }
    end
  end
end
