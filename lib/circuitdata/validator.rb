require_relative './validator/json_schema_error_parser'

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

    attr_reader :data

    def run_checks
      schema = Circuitdata.dereferenced_schema
      self.errors = JSON::Validator.fully_validate(
        schema, data, errors_as_objects: true
      )
      @errors.empty?
    end

    def errors=(schema_errors)
      @errors = schema_errors.map do |error|
        JsonSchemaErrorParser.translate(error)
      end
    end
  end
end