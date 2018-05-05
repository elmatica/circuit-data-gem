require_relative "../circuitdata_test"

class CircuitdataProductTest < CircuitdataTest
  def test_empty_product
    expected_data = json_fixture(:empty_product)
    product = Circuitdata::Product.new(id: '1', name: 'empty_product', data: nil)

    assert_hash_eql expected_data, product.data
    validator = Circuitdata::Validator.new(product.data)
    validator.valid?
    assert_hash_eql [], validator.errors
  end

  def test_setting_product_data
    expected_data = json_fixture(:setting_product_data)
    product = Circuitdata::Product.new(id: '1', name: 'empty_product', data: nil)

    product.product_data = {
      test: "something"
    }
    assert_hash_eql expected_data, product.data
  end

  def test_getting_layers
    example_data = json_fixture(:example_product)
    product = Circuitdata::Product.new(id: '1', name: 'test', data: example_data)
    assert_equal 6, product.layers.count
  end
end
