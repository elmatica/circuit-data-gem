require "spec_helper"

RSpec.describe Circuitdata::ExposedArea do
  subject { Circuitdata::ExposedArea.new(product) }
  let(:product) { build_product(id, data) }

  describe "Exposed area calculation" do
    let(:id) { "copper_coverage" }
    let(:data) { json_fixture(:exposed_copper) }
    it "gets the exposed copper value" do
      expect(subject.exposed_copper).to eql(5.0)
    end
    it "gets the copper coverage value" do
      expect(subject.copper_coverage).to eql(25.0)
    end
    context 'plated through holes are present' do
      before do
        product.processes.first[:function_attributes][:plated] = true
      end

      it "includes through holes when present" do
        expect(subject.barrel_area).to eql(20.09613988648319)
        expect(subject.exposed_copper).to eql(5.0)
      end

      it "is zero if number of holes is not present" do
        product.processes.first[:function_attributes][:number_of_holes] = nil
        expect(subject.barrel_area).to eql(0)
      end

      it "is zero if finished size is not present" do
        product.processes.first[:function_attributes][:finished_size] = nil
        expect(subject.barrel_area).to eql(0)
      end

      it "is zero if board thickness is not present" do
        product.set_question_answer(:metrics, :board, :thickness, nil)
        expect(subject.barrel_area).to eql(0)
      end
    end

  end

  describe "When the data is nil" do
    let(:id) { "empty_product" }
    let(:data) { nil }
    it "gets the exposed copper value" do
      expect(subject.exposed_copper).to eql(nil)
    end
    it "gets the copper coverage value" do
      expect(subject.copper_coverage).to eql(nil)
    end
  end

  def build_product(id, data)
    Circuitdata::Product.new(id: id, data: data)
  end
end
