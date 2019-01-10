module Circuitdata
  class ExposedArea

    def initialize(product)
      @product = product
    end

    def exposed_copper
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
      if coverage.empty?
        return nil
      end
      coverage.reduce(:+) / coverage.size.to_f
    end

    def copper_coverage
      coverage = []
      unless top_conductive.nil?
        if top_conductive[:coverage].is_a? Numeric
          coverage << top_conductive[:coverage]
        end
      end
      unless bottom_conductive.nil?
        if bottom_conductive[:coverage].is_a? Numeric
          coverage << bottom_conductive[:coverage]
        end
      end
      if coverage.empty?
        return nil
      end
      coverage.reduce(:+) / coverage.size.to_f
    end

    def barrel_area
      return 0 if board_thickness.nil?
      plated_through_holes.map{ |hole|  sum_holes_area(hole)}.sum
    end

    private

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

    def top_conductive
      return nil if conductive_dielectric_layers.first.nil?
      return nil if conductive_dielectric_layers.first[:function] != "conductive"
      conductive_dielectric_layers.first
    end

    def bottom_conductive
      return nil if conductive_dielectric_layers.last.nil?
      return nil if conductive_dielectric_layers.last[:function] != "conductive"
      conductive_dielectric_layers.last
    end

    def conductive_dielectric_layers
      layers.select{ |layer| ["conductive", "dielectric"].include?(layer[:function]) }
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

    # we are using the knowlegde that at least one conductive layer must
    # be present to separate the top and bottom solder masks from each other.
    def conductive_final_finish_layers
      layers.select{ |layer| ["conductive", "final_finish"].include?(layer[:function]) }
    end
  end
end
