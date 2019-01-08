module Circuitdata
  class Product
    BASIC_PRODUCT_STRUCTURE = {
      open_trade_transfer_package: {
        version: SCHEMA_VERSION,
        products: {},
        custom: {
          materials: {
            circuitdata: {},
          },
        },
      },
    }
    BASE_PATH = [:open_trade_transfer_package, :products]
    attr_accessor :id

    def self.from_data(data)
      products_hash = data.dig(*BASE_PATH)
      return [] if products_hash.nil?
      products_hash.keys.map do |k|
        self.new(id: k, data: data)
      end
    end

    def initialize(id:, data:)
      @id = id
      @data = data
    end

    def update_id(new_id)
      product_map = data.dig(*BASE_PATH)
      current_data = product_data
      product_map.delete(id.to_sym)
      product_map[new_id.to_sym] = {
        circuitdata: current_data,
      }
      @id = new_id
    end

    def product_data
      data.dig(*product_data_path)
    end

    def product_data=(new_data)
      Bury.bury(data, *product_data_path, new_data)
      product_data.merge!(version: SCHEMA_VERSION)
    end

    def materials_data
      data.dig(*materials_data_path)
    end

    def materials_data=(new_data)
      Bury.bury(data, *materials_data_path, new_data)
    end

    def data=(new_data)
      @data = new_data
    end

    def data
      @data ||= setup_basic_data
    end

    def question_answer(path)
      return nil if path.empty?
      path = path.map { |p| p.is_a?(String) ? p.to_sym : p }
      value = Bury.dig(product_data, *path)
      value
    end

    def set_question_answer(*path, value)
      return if value.nil? && question_answer(path).nil?
      Bury.bury(product_data, *path, value)
    end

    def layers
      product_data.fetch(:layers, [])
    end

    def processes
      product_data.fetch(:processes, [])
    end

    def sections
      product_data.fetch(:sections, [])
    end

    def metrics
      product_data.fetch(:metrics, {})
    end

    def product_data_path
      [:open_trade_transfer_package, :products, id.to_sym, :circuitdata]
    end

    def layer_name(uuid)
      layers.find { |l| l[:uuid] == uuid }&.fetch(:name, nil)
    end

    private

    def materials_data_path
      [:open_trade_transfer_package, :custom, :materials, :circuitdata]
    end

    def setup_basic_data
      new_data = BASIC_PRODUCT_STRUCTURE.deep_dup
      new_data.dig(:open_trade_transfer_package, :products)[id.to_sym] = {
        circuitdata: {
          version: SCHEMA_VERSION,
        },
      }
      new_data
    end
  end
end
