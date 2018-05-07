require_relative "../../circuitdata_test"

class CircuitdataValidatorJsonSchemaErrorParserTest < CircuitdataTest
  def test_required_property_error
    errors = generate_errors_and_translate(
      {},
      {type: "object", required: ["test"], properties:{test: {type: "string"}}}
    )
    assert_equal([{:source_path=>"/", :field=>"test", :problem=>"required_property_missing"}], errors)
  end

  def test_type_mismatch_error
    errors = generate_errors_and_translate(
      {test: 1},
      {type: "object", properties:{test: {type: "string"}}}
    )
    assert_equal([{:source_path=>"/test", :field=>"test", :actual=>"integer", :expected=>"string", :problem=>"type_mismatch"}], errors)
  end

  def test_additional_properties
    errors = generate_errors_and_translate(
      {test: 1},
      {type: "object", additionalProperties: false, properties:{}}
    )
    assert_equal([{:source_path=>"/", :field=>nil, :additional_properties=>["test"], :problem=>"additional_properties"}], errors)
  end

  def test_enum
    errors = generate_errors_and_translate(
      {test: "coffee"},
      {type: "object", properties:{test: {type: "string", enum: ["tea"]}}}
    )
    assert_equal([{:source_path=>"/test", :field=>"test", :problem=>"not_in_enum"}], errors)
  end

  def generate_errors_and_translate(data, schema)
    errors = JSON::Validator.fully_validate(
      schema, data, errors_as_objects: true
    )
    fail 'no errors generated' if errors.count == 0
    errors.map { |e| Circuitdata::Validator::JsonSchemaErrorParser.translate(e) }
  end
end