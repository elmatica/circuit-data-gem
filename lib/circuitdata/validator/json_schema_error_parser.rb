module Circuitdata
  class Validator
    class JsonSchemaErrorParser
      class<<self
        def translate(error)
          additional_data = extract_data(error[:message], error[:failed_attribute])
          fail "Unhandled error: #{error.inspect}" if additional_data.nil?

          path = error[:fragment].gsub('#', '')
          {
            source_path: path,
            field: path.split('/').last,
          }.merge(additional_data)
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
          when 'Enum'
            return { problem: 'not_in_enum' }
          end
        end
      end
    end
  end
end
