module Circuitdata
  class ProductIdValidator
    def self.validate(data)
      products = Product.from_data(data)
      products.flat_map do |product|
        validate_product(product)
      end
    end

    def self.validate_product(product)
      errors = []
      layer_ids = product.layers.map { |layer| layer.fetch(:uuid) }
      process_ids = product.processes.map { |process| process.fetch(:uuid) }
      ensure_unique(layer_ids, errors, [*product.product_data_path, :layers])
      ensure_unique(process_ids, errors, [*product.product_data_path, :processes])
      check_references(layer_ids, errors, product)
      errors
    end

    private

    def self.ensure_unique(ids, errors, base_path)
      ids.each_with_index do |id, index|
        previous_ids = ids.slice(0, index)
        previous_ids.each_with_index do |check_id, check_index|
          if check_id == id
            errors << build_error(problem: :duplicate_id, path: base_path + [index, :uuid])
          end
        end
      end
      errors
    end

    def self.check_references(layer_ids, errors, product)
      check_config_references(layer_ids, errors, product)
      check_process_references(layer_ids, errors, product)
    end

    def self.check_process_references(layer_ids, errors, product)
      product.processes.each_with_index do |process, index|
        next unless process[:function] == "holes"
        path = [:processes, index, :function_attributes]
        start_layer = process.dig(:function_attributes, :layer_start)
        if start_layer && !layer_ids.include?(start_layer)
          errors << build_error(
            problem: :unknown_layer_id,
            path: product.product_data_path + path + [:layer_start],
          )
        end

        stop_layer = process.dig(:function_attributes, :layer_stop)
        if stop_layer && !layer_ids.include?(stop_layer)
          errors << build_error(
            problem: :unknown_layer_id,
            path: product.product_data_path + path + [:layer_stop],
          )
        end
      end
    end

    def self.check_config_references(layer_ids, errors, product)
      config_layer_path = [:configuration, :markings, :layers]
      config_layer_ids = product.question_answer([:configuration, :markings, :layers]) || []
      config_layer_ids.each_with_index do |layer_id, index|
        unless layer_ids.include?(layer_id)
          errors << build_error(
            problem: :unknown_layer_id,
            path: product.product_data_path + config_layer_path + [index],
          )
        end
      end
    end

    def self.build_error(problem:, path:)
      {
        problem: problem,
        source_path: path,
      }
    end
  end
end
