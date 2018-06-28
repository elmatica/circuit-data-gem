require "spec_helper"

RSpec.describe Circuitdata::Validator do
  subject { Circuitdata::Validator.new(data) }

  context "empty product" do
    let(:data) { json_fixture(:empty_product) }

    it "should be valid" do
      expect(subject).to be_valid
    end
  end

  context "product is invalid" do
    let(:data) { {} }

    it "should not be valid" do
      expect(subject).not_to be_valid
      expect(subject.errors).to eql([{
        source_path: "/",
        field: "open_trade_transfer_package",
        problem: "required_property_missing",
      }])
    end
  end

  context "product has invalid value" do
    let(:data) { json_fixture(:invalid_product) }

    it "should not be valid" do
      expect(subject).not_to be_valid
      expect(subject.errors).to eql([{
        source_path: "/open_trade_transfer_package/products/test_product/circuitdata/configuration/country_of_origin/nato_member",
        field: "nato_member",
        problem: "type_mismatch",
        expected: "boolean",
        actual: "string",
      }])
    end
  end
end
