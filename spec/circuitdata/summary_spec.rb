require "spec_helper"

RSpec.describe Circuitdata::Summary do
  subject { described_class.new(product) }
  empty = {value: nil, empty: true}
  empty_product = {
    general: {
      base_materials: empty,
      number_of_conductive_layers: empty,
      minimum_track: empty,
      minimum_spacing: empty,
      final_finishes: empty,
      base_copper_thickness: empty
    },
    panel: {
      board_outline: empty,
      final_thickness: empty,
      panel_size: empty,
      pcbs_in_array: empty
    },
    standards: {},
    packaging: {},
    holes: {
      number_of_holes: empty,
      holes_density: empty,
      min_annular_ring: empty,
      min_through_hole_size: empty,
      max_aspect_ratio: empty
    },
    solder_mask: {
      solder_mask_sides: empty,
      solder_mask_materials: empty,
      solder_mask_finishes: empty,
      solder_mask_colors: empty
    },
    legend: {
      legend_materials: empty
    },
  }
  context "product is empty" do
    let(:product) { Circuitdata::Product.new(id: "test", data: nil) }

    it "generates an empty summary" do
      expect(subject.data).to eql(empty_product)
    end
  end

  context "product is not empty" do
    let(:product) { Circuitdata::Product.new(id: "test", data: json_fixture(:example_product)) }

    it "generates a summary" do
      product = empty_product.dup
      product[:general][:number_of_conductive_layers] = {value: 2, empty: false}
      product[:holes][:number_of_holes] = {value: 110, empty: false}
      product[:holes][:holes_density] = {value: 658.6, empty: false}
      product[:holes][:min_through_hole_size] = {value: 305.0, empty: false}
      product[:solder_mask][:solder_mask_sides] = {value: "Both", empty: false}
      product[:solder_mask][:solder_mask_materials] = {value: ["doc3", "doc"], empty: false}
      product[:legend][:legend_materials] = {value: ["doc4", "doc1"], empty: false}
      expect(subject.data).to eql(product)
    end
  end

  context "full product" do
    let(:product) { Circuitdata::Product.new(id: "test", data: json_fixture(:full_product)) }

    it "generates a summary" do
      expect(subject.data).to eql({
        general: {
          :base_materials => {value: "Rigid", empty: false},
          :number_of_conductive_layers => {value: 2, empty: false},
          :minimum_track => {value: 0.2, empty: false},
          :minimum_spacing => {value: 0.2, empty: false},
          :final_finishes => {value: ["ENIG"], empty: false},
          :base_copper_thickness => {value: 35, empty: false}
        },
        panel: {
          :board_outline => {value: "40.0 x 40.0 mm", empty: false},
          :final_thickness => {value: 1.62, empty: false},
          :panel_size => {value: "400.0 x 350.0 mm", empty: false},
          :pcbs_in_array => {value: 72, empty: false}
        },
        standards: {},
        packaging: {},
        holes: {
          :number_of_holes => {value: 110, empty: false},
          :holes_density => {value: 687.5, empty: false},
          :min_annular_ring => {value: 125.0, empty: false},
          :min_through_hole_size => {value: 305.0, empty: false},
          :max_aspect_ratio => {value: 5.31, empty: false}
        },
        solder_mask: {
          :solder_mask_sides => {value: "Both", empty: false},
          :solder_mask_materials => {value: ["HY-UVH900"], empty: false},
          :solder_mask_finishes => {value: ["matte"], empty: false},
          :solder_mask_colors => {value: ["green"], empty: false},
        },
        legend: {
          legend_materials: {value: ["CB100"], empty: false},
        },
      })
    end
  end
end
