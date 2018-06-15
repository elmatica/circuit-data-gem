require_relative "./json_validator/json_schema_error_parser"

module Circuitdata
  class JsonValidator
    def self.validate(schema, data)
      errors = JSON::Validator.fully_validate(
        schema, data, errors_as_objects: true,
      )
      convert_errors(errors)
    end

    private

    def self.convert_errors(schema_errors)
      schema_errors.map do |error|
        JsonSchemaErrorParser.translate(error)
      end
    end
  end
end
