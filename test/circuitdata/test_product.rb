require_relative "../circuitdata_test"

class CircuitdataProductTest < CircuitdataTest
  def test_empty_product
    expected_data = json_fixture(:empty_product)
    product = Circuitdata::Product.new(id: '1', name: 'empty_product', data: nil)

    assert_hash_eql expected_data, product.data
  end

  def test_setting_product_data
    expected_data = json_fixture(:setting_product_data)
    product = Circuitdata::Product.new(id: '1', name: 'empty_product', data: nil)

    product.product_data = {
      test: "something"
    }
    assert_hash_eql expected_data, product.data
  end
end
