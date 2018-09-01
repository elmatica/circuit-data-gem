require_relative "./json_validator/json_schema_error_parser"

module Circuitdata
  class JsonValidator
    def self.validate(schema, data)
      errors = JSON::Validator.fully_validate(
        schema, data, errors_as_objects: true,
      )
      simple_errors = errors.select { |e| error_is_simple?(e) }
      complex_errors = errors - simple_errors
      convert_simple_errors(simple_errors) +
        convert_complex_errors(complex_errors, schema, data)
    end

    private

    def self.convert_simple_errors(schema_errors)
      schema_errors.map do |error|
        JsonSchemaErrorParser.translate(error)
      end
    end

    def self.error_is_simple?(error)
      path = error[:fragment]
      !path.include?("circuitdata/layers") && !path.include?("circuitdata/processes")
    end

    def self.convert_complex_errors(errors, schema, data)
      errors.flat_map do |error|
        path = error[:fragment].slice(2..-1)
        parts = path.split("/")

        schema_element, data_element = get_element(parts, schema, data)
        func = data_element.fetch(:function)
        actual_schema = schema_element.fetch(:oneOf).find { |s| s.dig(:properties, :function, :enum).first == func }
        simpler_errors = JSON::Validator.fully_validate(
          actual_schema, data_element, errors_as_objects: true,
        )
        convert_simple_errors(simpler_errors).map do |err|
          err[:source_path] = "/#{path}#{err[:source_path]}"
          err
        end
      end
    end

    def self.get_element(parts, schema, data)
      return [schema, data] if parts.empty?
      part = parts.first
      if data.is_a?(Hash)
        sub_schema = schema.dig(:properties, part.to_sym)
        sub_schema ||= schema.dig(:patternProperties).values.first
        get_element(parts[1..-1], sub_schema, data[part.to_sym])
      else
        get_element(parts[1..-1], schema.dig(:items), data[part.to_i])
      end
    end
  end
end
