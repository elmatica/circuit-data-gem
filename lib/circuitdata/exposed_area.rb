module Circuitdata
  class ExposedArea

    def self.exposed_copper(data)
      ExposedArea.new(data).get_exposed_copper
    end

    def self.copper_coverage(data)
      ExposedArea.new(data).get_copper_coverage
    end

    def initialize(data)
      @data = data
    end

    def get_exposed_copper
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

    def get_copper_coverage
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

    def layers
      @data.fetch(:layers, [])
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
