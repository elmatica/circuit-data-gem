require "spec_helper"

RSpec.describe Circuitdata::JsonValidator::JsonSchemaErrorParser do
  it 'handles required properties' do
    errors = generate_errors_and_translate(
      {},
      {type: "object", required: ["test"], properties: {test: {type: "string"}}}
    )
    expect(errors).to eql([{:source_path => "/", :field => "test", :problem => "required_property_missing"}])
  end

  it 'handles type mismatches' do
    errors = generate_errors_and_translate(
      {test: 1},
      {type: "object", properties: {test: {type: "string"}}}
    )
    expect(errors).to eql([{:source_path => "/test", :field => "test", :actual => "integer", :expected => "string", :problem => "type_mismatch"}])
  end

  it 'handles additional properties' do
    errors = generate_errors_and_translate(
      {test: 1},
      {type: "object", additionalProperties: false, properties: {}}
    )
    expect(errors).to eql([{:source_path => "/", :field => nil, :additional_properties => ["test"], :problem => "additional_properties"}])
  end

  it 'handles enums' do
    errors = generate_errors_and_translate(
      {test: "coffee"},
      {type: "object", properties: {test: {type: "string", enum: ["tea"]}}}
    )
    expect(errors).to eql([{:source_path => "/test", :field => "test", :problem => "not_in_enum"}])
  end

  it 'handles patterns' do
    errors = generate_errors_and_translate(
      {test: "coffee"},
      {type: "object", properties: {test: {type: "string", pattern: "^tea$"}}}
    )
    expect(errors).to eql([{:source_path => "/test", :field => "test", :problem => "pattern_mismatch", pattern: '^tea$'}])
  end

  def generate_errors_and_translate(data, schema)
    errors = JSON::Validator.fully_validate(
      schema, data, errors_as_objects: true,
    )
    fail "no errors generated" if errors.count == 0
    errors.map { |e| described_class.translate(e) }
  end
end
