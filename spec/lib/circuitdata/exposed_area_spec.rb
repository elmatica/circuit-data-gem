require "spec_helper"

RSpec.describe Circuitdata::ExposedArea do
  subject { Circuitdata::ExposedArea.new(product) }
  let(:product) { build_product(id, data) }

  describe "Final finish total area calculation" do
    let(:id) { "final_finish_total_area" }
    let(:data) { json_fixture(:final_finish_total_area) }
    let(:final_finish_area_one_side) { 500.0 }
    let(:final_finish_area_total) { final_finish_area_one_side * 2}
    it "gets the final finish total area" do
      expect(subject.final_finish_total_area).to eql(final_finish_area_total)
    end

    it 'handles board area not being present' do
      product.set_question_answer(:metrics, :board, :area, nil)
      expect(subject.final_finish_total_area).to eql(nil)
    end

    context 'plated through holes are present' do
      let(:hole_area) { 20.09613988648319 }

      before do
        product.processes.first[:function_attributes][:plated] = true
      end

      it "calculates the barrel_area correctly" do
        expect(subject.barrel_area).to eql(hole_area)
      end

      it "includes the barrel_area in the final finish area total" do
        expect(subject.final_finish_total_area).to eql(final_finish_area_total + hole_area)
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
    it "gets the final finish total area" do
      expect(subject.final_finish_total_area).to eql(nil)
    end
  end

  def build_product(id, data)
    Circuitdata::Product.new(id: id, data: data)
  end
end
