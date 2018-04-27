module Circuitdata
  class Product
    attr_accessor :id, :name, :data

    def initialize(id:, name:, data:)
      @id = id
      @name = name
      @data = data
    end

    def product_data
      data.dig(:open_trade_transfer_package, :products, name.to_sym, :circuitdata)
    end
  end
end
