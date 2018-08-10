module Circuitdata
  class Schema
    CACHE_PATH = File.expand_path(File.join(__dir__, "..", "..", "data"))
    CACHE = {}
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
    def self.product_questions(cached: true)
      cached ? cached(:questions, :product) : questions_for_type(:products)
    end

    def self.profile_questions(cached: true)
      cached ? cached(:questions, :profile) : questions_for_type(:profiles)
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
        name: name_from_id(category_id),
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
      id = :"#{category.fetch(:id)}/#{question_id}"

      if question_schema.fetch(:type) == "object"
        category_questions << build_category(id, question_schema, path)
        return
      end

      question = {
        id: id,
        code: question_id,
        name: question_id.to_s.humanize,
        description: "",
      }
      category_questions << question

      [:default, :enforced, :restricted].each do |question_type|
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

    def self.name_from_id(id)
      id.to_s.split("/").last.humanize
    end

    def self.cached(*path)
      file_path = File.join(CACHE_PATH, *path.map(&:to_s)) + ".json"

      CACHE[file_path] ||= JSON.parse(File.read(file_path), symbolize_names: true)
    end
  end
end
