require "spec_helper"

RSpec.describe Circuitdata::ExposedArea do
  subject { Circuitdata::ExposedArea.new(
    product_data(id, data)) }

  describe "Exposed area calculation" do
    let(:id) { "copper_coverage" }
    let(:data) { json_fixture(:exposed_copper) }
    it "gets the exposed copper value" do
      expect(subject.get_exposed_copper).to eql(5.0)
    end
    it "gets the copper coverage value" do
      expect(subject.get_copper_coverage).to eql(25.0)
    end
  end

  describe "When the data is nil" do
    let(:id) { "empty_product" }
    let(:data) { nil }
    it "gets the exposed copper value" do
      expect(subject.get_exposed_copper).to eql(nil)
    end
    it "gets the copper coverage value" do
      expect(subject.get_copper_coverage).to eql(nil)
    end
  end

  def product_data(id, data)
    Circuitdata::Product.new(id: id, data: data).product_data
  end
end
