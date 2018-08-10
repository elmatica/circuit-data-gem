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

  describe "#set_question_answer" do
    let(:path) { ["default", "circuitdata", "sections", "count"] }

    context "value is not nil" do
      it "sets the value to the correct path" do
        subject.set_question_answer(path, 1234)

        set_value = subject.data.dig(:open_trade_transfer_package, :profiles, :default, :circuitdata, :sections, :count)
        expect(set_value).to eql(1234)
        validator = Circuitdata::Validator.new(subject.data)
        expect(validator).to be_valid
      end
    end

    context "value is nil" do
      it "does not set the value" do
        subject.set_question_answer(path, nil)

        expect(subject.data).to eql(Circuitdata::Profile::BASIC_PROFILE_STRUCTURE)
      end
    end
  end

  describe "#question_answer" do
    before do
      subject.profile_data[:default][:something] = "pizza"
    end

    it "returns the value at a specific path" do
      expect(subject.question_answer(["default", "something"])).to eql("pizza")
    end
  end
end
