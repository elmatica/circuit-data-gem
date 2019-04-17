module Circuitdata
  class JsonValidator
    class JsonSchemaErrorParser
      class << self
        def translate_all(errors)
          errors.map(&method(:translate)).reject do |error|
            error[:problem] == "pattern_mismatch" &&
              error[:pattern] == "^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$"
          end
        end

        def translate(error)
          additional_data = extract_data(error[:message], error[:failed_attribute])
          if additional_data.nil?
            fail "Unhandled error: #{error.inspect}"
          end

          path = error[:fragment].gsub("#", "")
          {
            source_path: path,
            field: path.split("/").last,
          }.merge(additional_data)
        end

        def extract_data(message, failed_attribute)
          case failed_attribute
          when "Required"
            field = message.match(/of '(.*)'/)[1]
            if !field
              fail "Unable to extract field from #{message.inspect}"
            end
            return { field: field, problem: "required_property_missing" }
          when "TypeV4"
            if message.include?("did not match the following type")
              matches = message.match(/of type (\S*) did not match the following type: (\S*)/)
              actual, expected = matches[1..2]
              return { actual: actual, expected: expected, problem: "type_mismatch" }
            end
          when "AdditionalProperties"
            matches = message.match(/contains additional properties (\[.*\]) outside/)
            additional_properties = JSON.parse(matches[1])
            return { additional_properties: additional_properties, problem: "additional_properties" }
          when "Enum"
            return { problem: "not_in_enum" }
          when "Pattern"
            regex = message.match(/did not match the regex '(\S*)' /)[1]
            return { problem: "pattern_mismatch", pattern: regex }
          when "Minimum"
            min = message.match(/did not have a minimum value of ([0-9\.])+, /)[1]
            return { problem: "min_not_met", expected: min }
          when "Maximum"
            min = message.match(/did not have a maximum value of ([0-9\.])+, /)[1]
            return { problem: "max_exceeded", expected: min }
          else
            if message.match?(/is not a uuid/)
              return { problem: "format_mismatch", expected: "uuid" }
            end
          end
        end
      end
    end
  end
end
