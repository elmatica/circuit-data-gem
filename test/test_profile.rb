require 'minitest/autorun'
require_relative '../lib/circuitdata'

class CircuitdataProfileSchemaTest < Minitest::Test
  def test_profile_schema
    refute_equal nil, Circuitdata::Profile.schema
  end

  def read_json_test_file(name)
    JSON.parse(
      File.read(File.join(__dir__, 'test_data/', name)),
      symbolize_names: true
    )
  end

  def reduced_profile_schema
    read_json_test_file('reduced_profile_schema.json')
  end

  def reduced_profile_schema_with_restriction
    read_json_test_file('reduced_profile_schema_with_restriction.json')
  end

  def test_profile_questions
    exp = [
      {
        id: :rigid_conductive_layer,
        name: 'Rigid conductive layer',
        questions: [
          {
            id: 'rigid_conductive_layer_copper_foil_roughness',
            code: :copper_foil_roughness,
            name: 'Copper foil roughness',
            description: "The roughness of the copper foil.",
            uom: ["um"],
            defaults: {
              schema: {
                type: "string",
                enum: ["S", "L", "V"],
                uom: ["um"],
              },
              path: "/open_trade_transfer_package/profiles/defaults/printed_circuits_fabrication_data/rigid_conductive_layer/copper_foil_roughness"
            },
            enforced: {
              schema: {
                type: "string",
                enum: ["S", "L", "V"],
                uom: ["um"],
              },
              path: "/open_trade_transfer_package/profiles/enforced/printed_circuits_fabrication_data/rigid_conductive_layer/copper_foil_roughness"
            }
          },
        ]
      }
    ]

    Circuitdata::Profile.stub(:schema, reduced_profile_schema) do
      result = Circuitdata::Profile.questions
      assert_same 1, result.length
      assert_equal exp.first, result.first
    end
  end

  def test_profile_questions_fix_missing_restriction_info
    exp = [
      {
        id: :rigid_conductive_layer,
        name: 'Rigid conductive layer',
        questions: [
          {
            id: 'rigid_conductive_layer_copper_foil_roughness',
            code: :copper_foil_roughness,
            name: 'Copper foil roughness',
            description: "The roughness of the copper foil.",
            uom: ["um"],
            defaults: {
              schema: {
                type: "string",
                enum: ["S", "L", "V"],
                uom: ["um"],
              },
              path: "/open_trade_transfer_package/profiles/defaults/printed_circuits_fabrication_data/rigid_conductive_layer/copper_foil_roughness"
            },
            restricted: {
              schema: {
                type: "array",
                items: {
                  type: "string",
                  enum: ["S", "L", "V"],
                  uom: ["um"],
                }
              },
              path: "/open_trade_transfer_package/profiles/restricted/printed_circuits_fabrication_data/rigid_conductive_layer/copper_foil_roughness"
            }
          },
        ]
      }
    ]

    Circuitdata::Profile.stub(:schema, reduced_profile_schema_with_restriction) do
      result = Circuitdata::Profile.questions
      assert_same 1, result.length
      assert_equal exp.first, result.first
    end
  end

  def test_profile_questions_no_stub
    question_sections = Circuitdata::Profile.questions
    non_matching_defaults_paths = []

    question_sections.each do |section|
      section[:questions].each do |question|
        defaults = question[:defaults]
        enforced = question[:enforced]
        both_present = !(defaults.nil? || enforced.nil? )
        if both_present && defaults[:descriptor] != enforced[:descriptor]
          non_matching_defaults_paths << defaults[:path]
        end
      end
    end

    assert_equal [], non_matching_defaults_paths
  end
end
