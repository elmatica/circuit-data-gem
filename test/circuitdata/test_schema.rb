require_relative "../circuitdata_test"

class CircuitdataSchemaTest < CircuitdataTest
  def test_layer_kinds
    kinds = Circuitdata::Schema.layer_kinds
    assert kinds.is_a?(Array)
    assert_equal "none", kinds.first
  end

  def test_process_kinds
    kinds = Circuitdata::Schema.process_kinds
    assert kinds.is_a?(Array)
    assert_equal "edge_bevelling", kinds.first
  end
end