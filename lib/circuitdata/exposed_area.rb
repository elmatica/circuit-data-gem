module Circuitdata
  class ExposedArea

    def initialize(product)
      @product = product
    end

    def final_finish_total_area
      return nil if board_area.nil?
      layer_final_finish_area+barrel_area
    end

    def barrel_area
      return 0 if board_thickness.nil?
      plated_through_holes.map{ |hole|  sum_holes_area(hole)}.sum
    end

    private

    def layer_final_finish_area
      coverage = final_finish_layers.map{ |layer| layer[:coverage]}.compact
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

    def final_finish_layers
      layers.select{ |layer| layer[:function] == "final_finish" }
    end
  end
end
