require 'minitest/autorun'
require 'circuitdata'

class CircuitdataTest < Minitest::Test
  def test_validate_json
    # fetch test data
    wrong_path= 'testfile-product.json'
    pass_product = File.join(File.dirname(__FILE__), 'test_data/pass_product.json')
    fail_product = File.join(File.dirname(__FILE__), 'test_data/fail_product.json')
    pass_restricted = File.join(File.dirname(__FILE__), 'test_data/pass_profile_restricted.json')
    fail_restricted = File.join(File.dirname(__FILE__), 'test_data/fail_profile_restricted.json')
    pass_enforced = File.join(File.dirname(__FILE__), 'test_data/pass_profile_enforced.json')
    fail_enforced = File.join(File.dirname(__FILE__), 'test_data/fail_profile_enforced.json')
    pass_capabilities = File.join(File.dirname(__FILE__), 'test_data/pass_capabilities.json')
    fail_capabilities = File.join(File.dirname(__FILE__), 'test_data/fail_capabilities.json')

    # RESULTS - should be updated to match the updated format
    fail_blank_data = {:error=>true, :message=>"Could not read the file", :errors=>{:validation=>{}, :restricted=>{}, :enforced=>{}, :capabilities=>{}}}
    pass_product_rst = {:error=>false, :message=>nil, :errors=>{:validation=>{}, :restricted=>{}, :enforced=>{}, :capabilities=>{}}}
    fail_product_rst = {:error=>true, :message=>"Could not validate the file against the CircuitData json schema", :errors=>{:validation=>{"#/open_trade_transfer_package/products/testproduct/printed_circuits_fabrication_data"=>["The property '#/open_trade_transfer_package/products/testproduct/printed_circuits_fabrication_data' contains additional properties [\"final_finsh\"] outside of the schema when none are allowed in schema http://schema.circuitdata.org/v1/ottp_circuitdata_schema.json"]}, :restricted=>{}, :enforced=>{}, :capabilities=>{}}}
    pass_restricted_rst = {:error=>false, :message=>nil, :errors=>{:validation=>{}, :restricted=>{}, :enforced=>{}, :capabilities=>{}}}
    fail_restricted_rst = {:error=>true, :message=>"The product to check did not meet the requirements", :errors=>{:validation=>{}, :restricted=>{"#/open_trade_transfer_package/products/testproduct/printed_circuits_fabrication_data/legend/color"=>["of type string matched the disallowed schema"]}, :enforced=>{}, :capabilities=>{}}}
    pass_enforced_rst = {:error=>false, :message=>nil, :errors=>{:validation=>{}, :restricted=>{}, :enforced=>{}, :capabilities=>{}}}
    fail_enforced_rst = {:error=>true, :message=>"The product to check did not meet the requirements", :errors=>{:validation=>{}, :restricted=>{}, :enforced=>{"#/open_trade_transfer_package/products/testproduct/printed_circuits_fabrication_data/legend/color"=>["value \"white\" did not match one of the following values: yellow"]}, :capabilities=>{}}}
    pass_capabilities_rst = {:error=>false, :message=>nil, :errors=>{:validation=>{}, :restricted=>{}, :enforced=>{}, :capabilities=>{}}}
    fail_capabilities_rst = {:error=>true, :message=>"The product to check did not meet the requirements", :errors=> {:validation=>{}, :restricted=>{}, :enforced=>{}, :capabilities=>{"#/open_trade_transfer_package/products/testproduct/printed_circuits_fabrication_data/rigid_conductive_layer/count"=>["did not have a minimum value of 10, inclusively"]}}}

    # TEST WITH NON-EXISTING FILE
    assert_equal fail_blank_data, Circuitdata.compatibility_checker(wrong_path)
    # TEST WITH SCHEMA COMPLIANT HASH
    assert_equal pass_product_rst, Circuitdata.compatibility_checker(pass_product)
    # TEST WITH NON SCHEMA COMPATIBLE JSON
    assert_equal fail_product_rst, Circuitdata.compatibility_checker(fail_product)
    # TEST WITH REQUIRED PROFILE AND PASS
    assert_equal pass_restricted_rst, Circuitdata.compatibility_checker(pass_product, pass_restricted)
    # TEST WITH REQURED PROFILE AND FAIL
    assert_equal fail_restricted_rst, Circuitdata.compatibility_checker(pass_product, fail_restricted)
    # TEST WITH ENFORCED PROFILE AND PASS
    assert_equal pass_enforced_rst, Circuitdata.compatibility_checker(pass_product, pass_enforced)
    # TEST WITH ENFORCED PROFILE AND FAIL
    assert_equal fail_enforced_rst, Circuitdata.compatibility_checker(pass_product, fail_enforced)
    # TEST WITH CAPABILITY PROFILE AND PASS
    assert_equal pass_capabilities_rst, Circuitdata.compatibility_checker(pass_product, pass_capabilities)
    # TEST WITH CAPABILITY PROFILE AND FAIL
    assert_equal fail_capabilities_rst, Circuitdata.compatibility_checker(pass_product, fail_capabilities)
  end
end
