require 'minitest/autorun'
require 'circuitdata'

class CircuitdataDereferencedSchemaTest < Minitest::Test
  def test_dereferenced_schema
    result = Circuitdata.dereferenced_schema

    # Check that there are no $refs left in the result
    assert_equal false, JSON.generate(result).include?('$ref')
  end

  def test_profile_schema
    refute_equal nil, Circuitdata.profile_schema
  end
end
