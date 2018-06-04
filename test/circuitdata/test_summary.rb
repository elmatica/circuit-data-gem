require_relative "../circuitdata_test"

class CircuitdataSummaryTest < CircuitdataTest
  def test_empty_product
    expected_data = {
      general: {},
      panel: {},
      standards: {},
      packaging: {},
      holes: {},
      solder_mask: {},
      materials: {},
      legend: {}
    }
    product = Circuitdata::Product.new(id: 'empty_product', data: nil)
    summary = Circuitdata::Summary.new(product)
    assert_hash_eql expected_data, summary.data
  end

  def test_example_product
    expected_data = {
      general: {
        :base_materials => ["doc4", "doc1", "doc3", "doc", "Top", "Bot"],
        :number_of_conductive_layers => 2
      },
      panel: {},
      standards: {},
      packaging: {},
      holes: {
        :number_of_holes => 110,
        :min_through_hole_size=>305.0
      },
      solder_mask: {},
      materials: {},
      legend: {
        materials: ["doc4", "doc1"]
      }
    }
    example_data = json_fixture(:example_product)
    product = Circuitdata::Product.new(id: 'test', data: example_data)
    summary = Circuitdata::Summary.new(product)
    assert_hash_eql expected_data, summary.data
  end
end
