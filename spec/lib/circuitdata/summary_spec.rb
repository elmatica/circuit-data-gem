require "spec_helper"

RSpec.describe Circuitdata::Summary do
  subject { described_class.new(product) }

  context "product is empty" do
    let(:product) { Circuitdata::Product.new(id: "test", data: nil) }

    it "generates an empty summary" do
      expect(subject.data).to eql({
        general: {},
        panel: {},
        standards: {},
        packaging: {},
        holes: {},
        solder_mask: {},
        legend: {},
      })
    end
  end

  context "product is not empty" do
    let(:product) { Circuitdata::Product.new(id: "test", data: json_fixture(:example_product)) }

    it "generates a summary" do
      expect(subject.data).to eql({
        general: {
          :number_of_conductive_layers => 2,
        },
        panel: {},
        standards: {},
        packaging: {},
        holes: {
          :number_of_holes => 110,
          :holes_density => 658.6,
          :min_through_hole_size => 305.0,
        },
        solder_mask: {
          solder_mask_materials: ["doc3", "doc"],
          solder_mask_sides: "Both",
        },
        legend: {
          legend_materials: ["doc4", "doc1"],
        },
      })
    end
  end

  context "full product" do
    let(:product) { Circuitdata::Product.new(id: "test", data: json_fixture(:full_product)) }

    it "generates a summary" do
      expect(subject.data).to eql({
        general: {
          :base_materials => "Rigid",
          :number_of_conductive_layers => 2,
          :minimum_track => 0.2,
          :minimum_spacing => 0.2,
          :final_finishes => ["ENIG"],
          :base_copper_thickness => 35,
        },
        panel: {
          :board_outline => "40.0 x 40.0 mm",
          :final_thickness => 1.62,
          :panel_size => "400.0 x 350.0 mm",
          :pcbs_in_array => 72,
        },
        standards: {},
        packaging: {},
        holes: {
          :number_of_holes => 110,
          :holes_density => 687.5,
          :min_annular_ring => 125.0,
          :min_through_hole_size => 305.0,
          :max_aspect_ratio => 5.31,
        },
        solder_mask: {
          :solder_mask_sides => "Both",
          :solder_mask_materials => ["HY-UVH900"],
          :solder_mask_finishes => ["matte"],
          :solder_mask_colors => ["green"],
        },
        legend: {
          legend_materials: ["CB100"],
        },
      })
    end
  end
end
