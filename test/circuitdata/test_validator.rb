require_relative "../circuitdata_test"

class CircuitdataValidatorTest < CircuitdataTest
  def test_empty_product
    file_data = json_fixture(:empty_product)
    validator = Circuitdata::Validator.new(file_data)
    assert validator.valid?
  end

  def test_invalid_product
    validator = Circuitdata::Validator.new({})
    assert !validator.valid?
    expected_errors = [{
      source_path: "/",
      field: "open_trade_transfer_package",
      problem: "required_property_missing",
    }]
    assert_hash_eql expected_errors, validator.errors
  end

  def test_invalid_product_value
    file_data = json_fixture(:invalid_product)
    validator = Circuitdata::Validator.new(file_data)
    assert !validator.valid?
    expected_errors = [{
      source_path: "/open_trade_transfer_package/products/test_product/circuitdata/configuration/country_of_origin/nato_member",
      field: "nato_member",
      problem: "type_mismatch",
      expected: "boolean",
      actual: "string",
    }]
    assert_hash_eql expected_errors, validator.errors
  end
end
