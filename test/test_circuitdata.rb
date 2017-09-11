require 'minitest/autorun'
require 'circuitdata'

class CircuitdataTest < Minitest::Test
  def test_validate_json

    # HASHES
    ok_product = {
      "open_trade_transfer_package": {
        "version": "1.0",
        "information": {
          "company": "Elmatica as",
          "created": "2017-08-28T09:49:37+02:00",
          "updated": "2017-08-28T09:49:37+02:00"
        },
        "products": {
          "testproduct": {
            "printed_circuits_fabrication_data": {
              "version": "0.6",
              "rigid_conductive_layer": {
                "count": 8,
                "minimum_external_track_width": 0.14,
                "minimum_external_spacing_width": 0.14,
                "external_base_copper_thickness": 17.1,
                "copper_coverage_average": 18.55,
                "copper_foil_roughness": "V"
              },
              "final_finish": [
                {
                  "finish": "b1_lfhasl",
                  "thickness_min": 1,
                  "thickness_max": 40
                }
              ],
              "legend": {
                "top": true,
                "bottom": false,
                "color": "white"
              }
            }
          }
        }
      }
    }
    not_ok_product = {
      "open_trade_transfer_package": {
        "version": "1.0",
        "information": {
          "company": "Elmatica as",
          "created": "2017-08-28T09:49:37+02:00",
          "updated": "2017-08-28T09:49:37+02:00"
        },
        "products": {
          "testproduct": {
            "printed_circuits_fabrication_data": {
              "version": "0.6",
              "rigid_conductive_layer": {
                "count": 8,
                "minimum_external_track_width": 0.14,
                "minimum_external_spacing_width": 0.14,
                "external_base_copper_thickness": 17.1,
                "copper_coverage_average": 18.55,
                "copper_foil_roughness": "V"
              },
              "final_finsh": [
                {
                  "finish": "b1_lfhasl",
                  "thickness_min": 1,
                  "thickness_max": 40
                }
              ],
              "legend": {
                "top": true,
                "bottom": false,
                "color": "white"
              }
            }
          }
        }
      }
    }
    enforced_profile_fail = {
      "open_trade_transfer_package": {
        "version": "1.0",
        "information": {
          "company": "Elmatica as",
          "created": "2017-08-28T09:49:37+02:00",
          "updated": "2017-08-28T09:49:37+02:00"
        },
        "profiles": {
          "enforced": {
            "printed_circuits_fabrication_data": {
              "version": "0.6",
              "legend": {
                "color": "yellow"
              }
            }
          }
        }
      }
    }
    enforced_profile_pass = {
      "open_trade_transfer_package": {
        "version": "1.0",
        "information": {
          "company": "Elmatica as",
          "created": "2017-08-28T09:49:37+02:00",
          "updated": "2017-08-28T09:49:37+02:00"
        },
        "profiles": {
          "enforced": {
            "printed_circuits_fabrication_data": {
              "version": "0.6",
              "legend": {
                "color": "white"
              }
            }
          }
        }
      }
    }
    restricted_profile_fail = {
      "open_trade_transfer_package": {
        "version": "1.0",
        "information": {
          "company": "Elmatica as",
          "created": "2017-08-28T09:49:37+02:00",
          "updated": "2017-08-28T09:49:37+02:00"
        },
        "profiles": {
          "restricted": {
            "printed_circuits_fabrication_data": {
              "version": "0.6",
              "legend": {
                "color": "white"
              }
            }
          }
        }
      }
    }
    restricted_profile_pass = {
      "open_trade_transfer_package": {
        "version": "1.0",
        "information": {
          "company": "Elmatica as",
          "created": "2017-08-28T09:49:37+02:00",
          "updated": "2017-08-28T09:49:37+02:00"
        },
        "profiles": {
          "restricted": {
            "printed_circuits_fabrication_data": {
              "version": "0.6",
              "legend": {
                "color": "yellow"
              }
            }
          }
        }
      }
    }
    capabilities_pass = {
      "open_trade_transfer_package": {
        "version": "1.0",
        "information": {
          "company": "Elmatica as",
          "created": "2017-08-28T09:49:37+02:00",
          "updated": "2017-08-28T09:49:37+02:00"
        },
        "capabilities": {
          "printed_circuits_fabrication_data": {
            "version": "0.6",
            "rigid_conductive_layer": {
              "count": "2...10"
            }
          }
        }
      }
    }
    capabilities_fail = {
      "open_trade_transfer_package": {
        "version": "1.0",
        "information": {
          "company": "Elmatica as",
          "created": "2017-08-28T09:49:37+02:00",
          "updated": "2017-08-28T09:49:37+02:00"
        },
        "capabilities": {
          "printed_circuits_fabrication_data": {
            "version": "0.6",
            "rigid_conductive_layer": {
              "count": "10...20"
            }
          }
        }
      }
    }



    # RESULTS
    nonexist_results = {:error=>true, :errormessage=>"Could not read the file", :validationserrors=>{}, :restrictederrors=>{}, :enforcederrors=>{}, :capabilitieserrors=>{}, :contains=>{:file1=>{:products=>0, :stackup=>false, :profile_defaults=>false, :profile_enforced=>false, :profile_restricted=>false, :capabilities=>false}, :file2=>{:products=>0, :stackup=>false, :profile_defaults=>false, :profile_enforced=>false, :profile_restricted=>false, :capabilities=>false}}}
    ok_result = {:error=>false, :errormessage=>"", :validationserrors=>{}, :restrictederrors=>{}, :enforcederrors=>{}, :capabilitieserrors=>{}, :contains=>{:file1=>{:products=>1, :stackup=>false, :profile_defaults=>false, :profile_enforced=>false, :profile_restricted=>false, :capabilities=>false}, :file2=>{:products=>0, :stackup=>false, :profile_defaults=>false, :profile_enforced=>false, :profile_restricted=>false, :capabilities=>false}}}
    not_ok_result = {:error=>true, :errormessage=>"Could not validate the file against the CircuitData json schema", :validationserrors=>{"#/open_trade_transfer_package/products/testproduct/printed_circuits_fabrication_data"=>["The property '#/open_trade_transfer_package/products/testproduct/printed_circuits_fabrication_data' contains additional properties [\"final_finsh\"] outside of the schema when none are allowed in schema http://schema.circuitdata.org/v1/ottp_circuitdata_schema.json"]}, :restrictederrors=>{}, :enforcederrors=>{}, :capabilitieserrors=>{}, :contains=>{:file1=>{:products=>0, :stackup=>false, :profile_defaults=>false, :profile_enforced=>false, :profile_restricted=>false, :capabilities=>false}, :file2=>{:products=>0, :stackup=>false, :profile_defaults=>false, :profile_enforced=>false, :profile_restricted=>false, :capabilities=>false}}}
    enforced_result_fail = {:error=>true, :errormessage=>"The product to check did not meet the requirements", :validationserrors=>{}, :restrictederrors=>{}, :enforcederrors=>{"#/open_trade_transfer_package/products/testproduct/printed_circuits_fabrication_data/legend/color"=>["value \"white\" did not match one of the following values: yellow"]}, :capabilitieserrors=>{}, :contains=>{:file1=>{:products=>1, :stackup=>false, :profile_defaults=>false, :profile_enforced=>false, :profile_restricted=>false, :capabilities=>false}, :file2=>{:products=>0, :stackup=>false, :profile_defaults=>false, :profile_enforced=>true, :profile_restricted=>false, :capabilities=>false}}}
    enforced_result_pass = {:error=>false, :errormessage=>"", :validationserrors=>{}, :restrictederrors=>{}, :enforcederrors=>{}, :capabilitieserrors=>{}, :contains=>{:file1=>{:products=>1, :stackup=>false, :profile_defaults=>false, :profile_enforced=>false, :profile_restricted=>false, :capabilities=>false}, :file2=>{:products=>0, :stackup=>false, :profile_defaults=>false, :profile_enforced=>true, :profile_restricted=>false, :capabilities=>false}}}
    restricted_result_fail = {:error=>true, :errormessage=>"The product to check did not meet the requirements", :validationserrors=>{}, :restrictederrors=>{"#/open_trade_transfer_package/products/testproduct/printed_circuits_fabrication_data/legend/color"=>["of type string matched the disallowed schema"]}, :enforcederrors=>{}, :capabilitieserrors=>{}, :contains=>{:file1=>{:products=>1, :stackup=>false, :profile_defaults=>false, :profile_enforced=>false, :profile_restricted=>false, :capabilities=>false}, :file2=>{:products=>0, :stackup=>false, :profile_defaults=>false, :profile_enforced=>false, :profile_restricted=>true, :capabilities=>false}}}
    restricted_result_pass = {:error=>false, :errormessage=>"", :validationserrors=>{}, :restrictederrors=>{}, :enforcederrors=>{}, :capabilitieserrors=>{}, :contains=>{:file1=>{:products=>1, :stackup=>false, :profile_defaults=>false, :profile_enforced=>false, :profile_restricted=>false, :capabilities=>false}, :file2=>{:products=>0, :stackup=>false, :profile_defaults=>false, :profile_enforced=>false, :profile_restricted=>true, :capabilities=>false}}}
    capabilities_result_pass = {:error=>false, :errormessage=>"", :validationserrors=>{}, :restrictederrors=>{}, :enforcederrors=>{}, :capabilitieserrors=>{}, :contains=>{:file1=>{:products=>1, :stackup=>false, :profile_defaults=>false, :profile_enforced=>false, :profile_restricted=>false, :capabilities=>false}, :file2=>{:products=>0, :stackup=>false, :profile_defaults=>false, :profile_enforced=>false, :profile_restricted=>false, :capabilities=>true}}}
    capabilities_result_fail = {:error=>true, :errormessage=>"The product to check did not meet the requirements", :validationserrors=>{}, :restrictederrors=>{}, :enforcederrors=>{}, :capabilitieserrors=>{"#/open_trade_transfer_package/products/testproduct/printed_circuits_fabrication_data/rigid_conductive_layer/count"=>["did not have a minimum value of 10, inclusively"]}, :contains=>{:file1=>{:products=>1, :stackup=>false, :profile_defaults=>false, :profile_enforced=>false, :profile_restricted=>false, :capabilities=>false}, :file2=>{:products=>0, :stackup=>false, :profile_defaults=>false, :profile_enforced=>false, :profile_restricted=>false, :capabilities=>true}}}


    # TEST WITH NON SCHEMA COMPATIBLE JSON
    assert_equal not_ok_result, Circuitdata.compatibility_checker( not_ok_product )
    # TEST WITH SCHEMA COMPLIANT HASH
    assert_equal ok_result, Circuitdata.compatibility_checker( ok_product )
    # TEST WITH NON-EXISTING FILE
    assert_equal nonexist_results, Circuitdata.compatibility_checker( 'testfile-product.json' )
    # TEST WITH ENFORCED PROFILE AND FAIL
    assert_equal enforced_result_fail, Circuitdata.compatibility_checker( ok_product, enforced_profile_fail )
    # TEST WITH ENFORCED PROFILE AND PASS
    assert_equal enforced_result_pass, Circuitdata.compatibility_checker( ok_product, enforced_profile_pass )
    # TEST WITH REQURED PROFILE AND FAIL
    assert_equal restricted_result_fail, Circuitdata.compatibility_checker( ok_product, restricted_profile_fail )
    # TEST WITH REQUIRED PROFILE AND PASS
    assert_equal restricted_result_pass, Circuitdata.compatibility_checker( ok_product, restricted_profile_pass )
    # TEST WITH CAPABILITY PROFILE AND FAIL
    assert_equal capabilities_result_fail, Circuitdata.compatibility_checker( ok_product, capabilities_fail )
    # TEST WITH CAPABILITY PROFILE AND PASS
    assert_equal capabilities_result_pass, Circuitdata.compatibility_checker( ok_product, capabilities_pass )


    #assert_equal nonexistresults, Circuitdata.compatibility_checker( 'test/testfiles/testfile-product-fails.json' )
    #assert_equal nonexistresults, Circuitdata.compatibility_checker( 'test/testfiles/testfile-product.json', nil, false )
  end
end
