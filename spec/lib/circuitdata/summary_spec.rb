require "spec_helper"

RSpec.describe Circuitdata::Summary do
  subject { described_class.new(product) }

  context "product is empty" do
    let(:product) { Circuitdata::Product.new(id: "test", data: nil) }

    it "generates an empty summary" do
      expect(subject.data).to eql({
        :base_materials => nil,
        :number_of_conductive_layers => nil,
        :board_outline => nil,
        :final_thickness => nil,
        :minimum_track => nil,
        :minimum_spacing => nil,
        :min_through_hole_size => nil,
        :max_aspect_ratio => nil
      })
    end
  end

  context "product is not empty" do
    let(:product) { Circuitdata::Product.new(id: "test", data: json_fixture(:example_product)) }

    it "generates a summary" do
      expect(subject.data).to eql({
        :base_materials => nil,
        :number_of_conductive_layers => 2,
        :board_outline => nil,
        :final_thickness => nil,
        :minimum_track => nil,
        :minimum_spacing => nil,
        :min_through_hole_size => 305.0,
        :max_aspect_ratio => nil
      })
    end
  end

  context "full product" do
    let(:product) { Circuitdata::Product.new(id: "test", data: json_fixture(:full_product)) }

    it "generates a summary" do
      expect(subject.data).to eql({
        :base_materials => "Rigid",
        :number_of_conductive_layers => 2,
        :board_outline => "40.0 x 40.0 mm",
        :final_thickness => 1.62,
        :minimum_track => 0.2,
        :minimum_spacing => 0.2,
        :min_through_hole_size => 305.0,
        :max_aspect_ratio => 5.31
      })
    end
  end
end
