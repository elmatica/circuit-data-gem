module Circuitdata
  class Validator
    attr_reader :errors

    def initialize(data)
      @data = data
    end

    def valid?
      return @valid if defined? @valid
      @valid = run_checks
    end

    private

    attr_reader :data, :schema

    def run_checks
      @errors = JsonValidator.validate(Circuitdata.dereferenced_schema, data)
      @errors.empty?
    end
  end
end
