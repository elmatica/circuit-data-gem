module Circuitdata
  class Schema
    BASE_PATH = [
      :properties,
      :open_trade_transfer_package,
      :properties,
    ]
    TYPE_PATH = {
      profiles: BASE_PATH + [:profiles] + [:patternProperties,
                                           :"^(?!typeofprofile$).*",
                                           :properties,
                                           :circuitdata,
                                           :properties],
      products: BASE_PATH + [:products] + [:patternProperties,
                                           :"^(?!generic$).*",
                                           :properties,
                                           :circuitdata,
                                           :properties],
    }
    def self.product_questions
      questions_for_type(:products)
    end

    def self.profile_questions
      questions_for_type(:profiles)
    end

    def self.questions_for_type(type)
      pointer_path = TYPE_PATH.fetch(type)
      result = []
      type_schema(type).each do |category_id, category_schema|
        next if category_id == :version
        category = {
          id: category_id,
          name: category_id.to_s.humanize,
          questions: [],
          array?: category_schema[:type] == "array",
        }
        result << category
        prop_path = [:properties]
        prop_path.unshift(:items) if category[:array?]
        category_schema.dig(*prop_path).each do |question_id, question_schema|
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
        description: "",
      }
      category_questions << question

      [:defaults, :required, :forbidden].each do |question_type|
        schema = question_schema.dup
        question[:description] = schema.delete(:description) || question[:description]

        question[question_type] = {
          schema: schema,
          path: json_pointer(path + [category[:id], question_id], question_type),
        }
        question[:uom] ||= schema[:uom]
      end
    end

    def self.json_pointer(path_parts, type)
      ([""] + path_parts - [:properties, :patternProperties])
        .join("/")
        .sub("^(?!typeofprofile$).*", type.to_s)
    end

    def self.layer_kinds
      product_schema = type_schema(:products)
      product_schema.dig(:layers, :items, :properties, :function, :enum)
    end

    def self.process_kinds
      product_schema = type_schema(:products)
      product_schema.dig(:processes, :items, :properties, :function, :enum)
    end

    def self.type_schema(type)
      schema = Circuitdata.dereferenced_schema
      pointer_path = TYPE_PATH.fetch(type)
      schema.dig(*pointer_path)
    end
  end
end
