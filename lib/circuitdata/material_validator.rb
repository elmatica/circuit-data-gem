module Circuitdata
  class MaterialValidator
    attr_reader :errors

    MATERIAL_SCHEMA_PATH = [
      :properties,
      :open_trade_transfer_package,
      :properties,
      :custom,
      :properties,
      :materials,
      :properties,
      :circuitdata,
      :patternProperties,
      :".*",
    ]

    def initialize(data)
      @data = data
    end

    def valid?
      return @valid if defined? @valid
      @valid = run_checks
    end

    private

    attr_reader :data

    def run_checks
      @errors = JsonValidator.validate(schema, data)
      @errors.empty?
    end

    def schema
      Circuitdata.dereferenced_schema.dig(*MATERIAL_SCHEMA_PATH)
    end
  end
end
