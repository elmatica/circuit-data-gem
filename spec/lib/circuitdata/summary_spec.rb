require "spec_helper"

RSpec.describe Circuitdata::Summary do
  subject { described_class.new(product) }

  context "product is empty" do
    let(:product) { Circuitdata::Product.new(id: "test", data: nil) }

    it "generates an empty summary" do
      expect(subject.base_materials).to eql(nil)
      expect(subject.number_of_conductive_layers).to eql(0)
      expect(subject.board_outline).to eql(nil)
      expect(subject.final_thickness).to eql(nil)
      expect(subject.minimum_track).to eql(nil)
      expect(subject.minimum_spacing).to eql(nil)
      expect(subject.min_through_hole_size).to eql(nil)
      expect(subject.max_aspect_ratio).to eql(nil)
    end
  end

  context "product is not empty" do
    let(:product) { Circuitdata::Product.new(id: "test", data: json_fixture(:example_product)) }

    it "generates a summary" do
      expect(subject.base_materials).to eql(nil)
      expect(subject.number_of_conductive_layers).to eql(2)
      expect(subject.board_outline).to eql(nil)
      expect(subject.final_thickness).to eql(nil)
      expect(subject.minimum_track).to eql(nil)
      expect(subject.minimum_spacing).to eql(nil)
      expect(subject.min_through_hole_size).to eql(305.0)
      expect(subject.max_aspect_ratio).to eql(nil)
    end
  end

  context "full product" do
    let(:product) { Circuitdata::Product.new(id: "test", data: json_fixture(:full_product)) }

    it "generates a summary" do
      expect(subject.base_materials).to eql("Rigid")
      expect(subject.number_of_conductive_layers).to eql(2)
      expect(subject.board_outline).to eql("40.0 x 40.0 mm")
      expect(subject.final_thickness).to eql(1.62)
      expect(subject.minimum_track).to eql(0.2)
      expect(subject.minimum_spacing).to eql(0.2)
      expect(subject.min_through_hole_size).to eql(305.0)
      expect(subject.max_aspect_ratio).to eql(5.31)
    end
  end
end
