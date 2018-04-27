module Circuitdata
  class Product
    BASIC_PRODUCT_STRUCTURE = {
      open_trade_transfer_package: {
        version: SCHEMA_VERSION,
        products: {}
      }
    }
    attr_accessor :id, :name, :data

    def initialize(id:, name:, data:)
      @id = id
      @name = name
      @data = data
    end

    def product_data
      data.dig(*product_data_path)
    end

    def product_data=(new_data)
      product_data.merge!(new_data)
    end

    def data
      @data ||= setup_basic_data
    end

    private

    def product_data_path
      [:open_trade_transfer_package, :products, name.to_sym, :circuitdata]
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
