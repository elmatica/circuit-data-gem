require "spec_helper"

RSpec.describe Circuitdata::Product do
  subject { Circuitdata::Product.new(id: id, data: data) }
  let(:id) { "empty_product" }
  let(:data) { nil }

  describe "product initialization" do
    let(:expected_result) { json_fixture(:empty_product) }

    it "creates valid empty products" do
      expect(subject.data).to eql(expected_result)

      validator = Circuitdata::Validator.new(subject.data)
      expect(validator).to be_valid
    end
  end

  describe "#product_data" do
    let(:expected_result) { json_fixture(:setting_product_data) }

    it "sets the product data correctly" do
      subject.product_data = {
        test: "something",
      }
      expect(subject.data).to eql(expected_result)
    end
  end

  describe "#layers" do
    let(:id) { "test" }
    let(:data) { json_fixture(:example_product) }

    it "returns all the layers for the product" do
      expect(subject.layers.length).to eql(6)
    end
  end

  describe "#processes" do
    let(:id) { "test" }
    let(:data) { json_fixture(:example_product) }

    it "returns all the processes for the product" do
      expect(subject.processes.length).to eql(2)
    end
  end

  describe "#sections" do
    let(:id) { "test" }
    let(:data) { json_fixture(:example_product) }

    it "returns all the sections for the product" do
      expect(subject.sections.length).to eql(1)
    end
  end

  describe "#update_id" do
    let(:id) { "test" }
    let(:data) { json_fixture(:example_product) }

    it "changes the product id" do
      subject.update_id("another_test")

      expect(subject.id).to eql("another_test")
      expect(subject.product_data).not_to be(nil)
    end
  end

  describe "#set_question_answer" do
    it "changes the answer value id" do
      subject.set_question_answer(:sections, 0, :name, "main_rigid")
      expect(subject.sections).to eql([
        {
          "name": "main_rigid",
        },
      ])
    end
  end

  describe ".from_data" do
    subject { described_class }

    let(:data) { json_fixture(:multiple_products) }

    it "returns all the products in the file" do
      products = subject.from_data(data)
      expect(products.count).to eql(2)
      expect(products.map(&:id)).to eql([:empty_product, :empty_product_2])
    end
  end

  describe ".layer_name" do
    let(:data) { nil }

    it "returns nil when the layer does not exist" do
      expect(subject.layer_name("some-uuid")).to be(nil)
    end

    context "layers are present" do
      before do
        subject.set_question_answer(:layers, 0, :name, "Topping")
        subject.set_question_answer(:layers, 0, :uuid, "some-uuid")
      end

      it "returns the layer name" do
        expect(subject.layer_name("some-uuid")).to eql("Topping")
      end
    end
  end
end
