require "spec_helper"

RSpec.describe Circuitdata::Schema do
  subject { Circuitdata::Schema }

  describe ".layer_kinds" do
    it "returns the layer kinds" do
      kinds = subject.layer_kinds
      expect(kinds).to be_a(Array)
      expect(kinds.first).to eql("none")
    end
  end

  describe ".process_kinds" do
    it "returns the process kinds" do
      kinds = subject.process_kinds
      expect(kinds).to be_a(Array)
      expect(kinds.first).to eql("edge_bevelling")
    end
  end

  describe ".product_questions" do
    it "generates product questions without exceptions" do
      subject.product_questions
    end
  end
end
