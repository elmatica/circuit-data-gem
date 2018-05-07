require_relative "../circuitdata_test"

class CircuitdataProductTest < CircuitdataTest
  def test_empty_product
    expected_data = json_fixture(:empty_product)
    product = Circuitdata::Product.new(id: 'empty_product', data: nil)

    assert_hash_eql expected_data, product.data
    validator = Circuitdata::Validator.new(product.data)
    validator.valid?
    assert_hash_eql [], validator.errors
  end

  def test_setting_product_data
    expected_data = json_fixture(:setting_product_data)
    product = Circuitdata::Product.new(id: 'empty_product', data: nil)

    product.product_data = {
      test: "something"
    }
    assert_hash_eql expected_data, product.data
  end

  def test_getting_layers
    example_data = json_fixture(:example_product)
    product = Circuitdata::Product.new(id: 'test', data: example_data)
    assert_equal 6, product.layers.count
  end

  def test_getting_all_products_from_a_file
    example_data = json_fixture(:multiple_products)
    products = Circuitdata::Product.from_data(example_data)
    assert_equal 2, products.count
    assert_equal [:empty_product, :empty_product_2], products.map(&:id)
  end

  def test_update_product_id
    example_data = json_fixture(:example_product)
    product = Circuitdata::Product.new(id: 'test', data: example_data)
    product.update_id('another_test')
    assert_equal 'another_test', product.id
    assert_equal false, product.product_data.nil?
  end
end
