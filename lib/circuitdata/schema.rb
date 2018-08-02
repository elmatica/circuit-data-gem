module Circuitdata
  class Schema
    BASE_PATH = [
      :properties,
      :open_trade_transfer_package,
      :properties,
    ]
    TYPE_PATH = {
      profiles: BASE_PATH + [:profiles] + [:properties,
                                           :enforced,
                                           :properties,
                                           :circuitdata,
                                           :properties],
      products: BASE_PATH + [:products] + [:patternProperties,
                                           :".*",
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
        result << build_category(category_id, category_schema, pointer_path)
      end
      result
    end

    def self.build_category(category_id, category_schema, pointer_path)
      category = {
        id: category_id,
        name: category_id.to_s.humanize,
        questions: [],
        array?: category_schema[:type] == "array",
      }
      if category_schema.has_key?(:properties)
        prop_path = [:properties]
      elsif category_schema.has_key?(:patternProperties)
        prop_path = [:patternProperties]
      elsif category_schema.fetch(:type) == "array"
        prop_path = [:items, :properties]
      else
        raise "Unknown type"
      end

      questions = category_schema.dig(*prop_path)
      questions.each do |question_id, question_schema|
        add_questions_to_category(category, question_id, question_schema, pointer_path)
      end
      category
    end

    def self.add_questions_to_category(category, question_id, question_schema, path)
      category_questions = category[:questions]

      if question_schema.fetch(:type) == "object"
        category_questions << build_category(question_id, question_schema, path)
        return
      end

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
        .sub("enforced", type.to_s)
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
