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
        additional_data = extract_data(error[:message], error[:failed_attribute])
        path = error[:fragment].gsub('#', '')
        {
          source_path: path,
          field: path.split('/').last,
        }.merge(additional_data)
      end
    end

    def extract_data(message, failed_attribute)
      case failed_attribute
      when "Required"
        field = message.match(/of '(.*)'/)[1]
        if !field
          fail "Unable to extract field from #{message.inspect}"
        end
        return { field: field, problem: 'required_property_missing' }
      when "TypeV4"
        if message.include?("did not match the following type")
          matches = message.match(/of type (\S*) did not match the following type: (\S*)/)
          actual, expected = matches[1..2]
          return { actual: actual, expected: expected, problem: 'type_mismatch' }
        end
      when 'AdditionalProperties'
        matches = message.match(/contains additional properties (\[.*\]) outside/)
        additional_properties = JSON.parse(matches[1])
        return { additional_properties: additional_properties, problem: 'additional_properties' }
      end
      fail "Unhandled error message: #{message.inspect}"
    end
  end
end