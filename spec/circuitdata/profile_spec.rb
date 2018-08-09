require "spec_helper"

RSpec.describe Circuitdata::Profile do
  subject { described_class.new(data: data) }
  let(:data) { nil }

  describe "profile initialization" do
    let(:expected_result) { json_fixture(:empty_profile) }

    it "creates a valid empty profile" do
      expect(subject.data).to eql(expected_result)

      validator = Circuitdata::Validator.new(subject.data)
      expect(validator).to be_valid
    end
  end
end
