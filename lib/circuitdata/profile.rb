module Circuitdata
  class Profile
    def self.schema
      schema = Circuitdata.dereferenced_schema
      ottp = schema.dig(
        :properties,
        :open_trade_transfer_package,
      )
      ottp[:properties] = ottp[:properties].slice(:profiles)
      schema
    end

    def self.questions
      questions_for_type(:profiles, schema)
    end

    private

    CATEGORY_PATH = [:properties, :printed_circuits_fabrication_data, :properties]

    def self.questions_for_type(type, schema)
      pointer_path = [
        :properties,
        :open_trade_transfer_package,
        :properties,
        type,
        :properties
      ]
      types_schema = schema.dig(*pointer_path)
      result = []
      types_schema.each do |question_type, type_schema|
        categories_schema = type_schema.dig(*CATEGORY_PATH)
        categories_schema.each do |category_id, category_schema|
          next if category_id == :version
          category = result.find {|cat| cat[:id] == category_id }
          if category.nil?
            category = {
              id: category_id,
              name: category_id.to_s.humanize,
              questions: []
            }
            result << category
          end
          extract_questions_for_category(
            question_type,
            category,
            category_schema,
            pointer_path + [question_type] + CATEGORY_PATH + [category_id]
          )
        end
      end
      result
    end

    def self.extract_questions_for_category(question_type, category, category_schema, path)
      # Ignore question arrays for now.
      return if category_schema[:type] == "array"
      category_questions = category[:questions]

      category_schema[:properties].each do |question_code, descriptor|
        question = category_questions.find {|question| question[:code] == question_code }
        if question.nil?
          question = {
            code: question_code,
            name: question_code.to_s.humanize,
            description: ''
          }
          category_questions << question
        end
        schema = descriptor.dup
        question[:description] = schema.delete(:description) || question[:description]
        question[question_type] = {
          schema: schema,
          path: json_pointer(path + [question_code])
        }
      end
    end

    def self.json_pointer(path_parts)
      ([""] + path_parts - [:properties]).join('/')
    end
  end
end
