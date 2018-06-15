require_relative "../circuitdata_test"

class CircuitdataMaterialValidatorTest < CircuitdataTest
  def test_material_validator
    material = json_fixture(:material)
    validator = Circuitdata::MaterialValidator.new(material)
    validator.valid?
    assert_hash_eql [], validator.errors
  end
end
