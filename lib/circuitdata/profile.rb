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
        :patternProperties,
        :"^(?!typeofprofile$).*",
        :properties,
        :circuitdata,
        :properties,
      ]
      types_schema = schema.dig(*pointer_path)
      result = []
      types_schema.each do |category_id, category_schema|
        next if category_id == :version
        category = {
          id: category_id,
          name: category_id.to_s.humanize,
          questions: [],
        }
        result << category
        category_schema.dig(:properties).each do |question_id, question_schema|
          add_questions_to_category(category, question_id, question_schema, pointer_path)
        end
      end
      result
    end

    def self.add_questions_to_category(category, question_id, question_schema, path)
      category_questions = category[:questions]
      question = {
        id: "#{category[:id]}_#{question_id}",
        code: question_id,
        name: question_id.to_s.humanize,
        description: '',
      }
      category_questions << question

      [:defaults, :required, :forbidden].each do |question_type|
        schema = question_schema.dup
        question[:description] = schema.delete(:description) || question[:description]

        question[question_type] = {
          schema: schema,
          path: json_pointer(path + [question_id], question_type),
        }
        question[:uom] ||= schema[:uom]
      end
    end

    def self.json_pointer(path_parts, type)
      ([""] + path_parts - [:properties, :patternProperties])
        .join('/')
        .sub('^(?!typeofprofile$).*', type.to_s)
    end
  end
end
