module Circuitdata
  class Product
    BASIC_PRODUCT_STRUCTURE = {
      open_trade_transfer_package: {
        version: SCHEMA_VERSION,
        products: {},
        custom: {
          materials: {
            circuitdata: {}
          }
        }
      }
    }
    BASE_PATH = [:open_trade_transfer_package, :products]
    attr_accessor :id, :name

    def self.from_data(data)
      data.dig(*BASE_PATH).map do |k|
        self.new(id: k, name: k, data: data)
      end
    end

    def initialize(id:, name:, data:)
      @id = id
      @name = name
      @data = data
    end

    def rename(new_name)
      product_map = data.dig(*BASE_PATH)
      current_data = product_data
      product_map.delete(name.to_sym)
      product_map[new_name.to_sym] = {
        circuitdata: current_data
      }
      @name = new_name
    end

    def product_data
      data.dig(*product_data_path)
    end

    def product_data=(new_data)
      product_data.merge!(new_data)
    end

    def materials_data
      data.dig(*materials_data_path)
    end

    def materials_data=(new_data)
      materials_data.merge!(new_data)
    end

    def data
      @data ||= setup_basic_data
    end

    def question_answer(path)
      return nil if path.empty?
      path = path.map(&:to_sym)
      value = product_data.dig(*path)
      value
    end

    def layers
      product_data.fetch(:layers)
    end

    private

    def product_data_path
      [:open_trade_transfer_package, :products, name.to_sym, :circuitdata]
    end

    def materials_data_path
      [:open_trade_transfer_package, :custom, :materials, :circuitdata]
    end

    def setup_basic_data
      new_data = BASIC_PRODUCT_STRUCTURE.deep_dup
      new_data.dig(:open_trade_transfer_package, :products)[name.to_sym] = {
        circuitdata: {
          version: SCHEMA_VERSION
        }
      }
      new_data
    end
  end
end
