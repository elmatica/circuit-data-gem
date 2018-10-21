require "spec_helper"

RSpec.describe Circuitdata::ProductIdValidator do
  subject { described_class }

  describe ".validate_product" do
    let(:product) { Circuitdata::Product.new(id: "pizza", data: nil) }

    it "is valid with empty file" do
      expect(subject.validate_product(product)).to eql([])
    end

    context "with duplicate id present for layers" do
      before do
        product.set_question_answer(:layers, 0, :uuid, "cheese-1")
        product.set_question_answer(:layers, 1, :uuid, "cheese-1")
      end

      it "returns an error" do
        expect(subject.validate_product(product)).to eql([{
          problem: :duplicate_id,
          source_path: [:open_trade_transfer_package, :products, :pizza, :circuitdata, :layers, 1, :uuid],
        }])
      end
    end

    context "with duplicate id present for processes" do
      before do
        product.set_question_answer(:processes, 0, :uuid, "cheese-1")
        product.set_question_answer(:processes, 1, :uuid, "cheese-1")
      end

      it "returns an error" do
        expect(subject.validate_product(product)).to eql([{
          problem: :duplicate_id,
          source_path: [:open_trade_transfer_package, :products, :pizza, :circuitdata, :processes, 1, :uuid],
        }])
      end
    end

    context "configuration references layers" do
      before do
        product.set_question_answer(:configuration, :markings, :layers, layers)
        product.set_question_answer(:layers, 0, :uuid, "cheese-2")
      end

      let(:layers) { [] }

      it "is valid with empty layers" do
        expect(subject.validate_product(product)).to eql([])
      end

      context "referenced layers are valid" do
        let(:layers) { ["cheese-2"] }

        it "is valid" do
          expect(subject.validate_product(product)).to eql([])
        end
      end

      context "when there is a layer referenced which does not exist" do
        let(:layers) { ["cake"] }

        it "is not valid" do
          expect(subject.validate_product(product)).to eql([{
            problem: :unknown_layer_id,
            source_path: [:open_trade_transfer_package, :products, :pizza, :circuitdata, :configuration, :markings, :layers, 0],
          }])
        end
      end
    end

    context "process references layers" do
      before do
        product.set_question_answer(:processes, 0, :function, "holes")
        product.set_question_answer(:processes, 0, :uuid, "bake-1")
        product.set_question_answer(:layers, 0, :uuid, "cheese-2")
      end

      it "is valid with no reference info in the process" do
        expect(subject.validate_product(product)).to eql([])
      end

      context "referenced layers are valid" do
        before do
          product.set_question_answer(:processes, 0, :function_attributes, :layer_start, "cheese-2")
          product.set_question_answer(:processes, 0, :function_attributes, :layer_stop, "cheese-2")
        end

        it "is valid" do
          expect(subject.validate_product(product)).to eql([])
        end
      end

      context "when there is a layer referenced which does not exist" do
        before do
          product.set_question_answer(:processes, 0, :function_attributes, :layer_start, "cheese-99")
          product.set_question_answer(:processes, 0, :function_attributes, :layer_stop, "cheese-99")
        end

        it "is not valid" do
          expect(subject.validate_product(product)).to eql(
            [
              {
                problem: :unknown_layer_id,
                source_path: [:open_trade_transfer_package, :products, :pizza, :circuitdata, :processes, 0, :function_attributes, :layer_start],
              },
              {
                problem: :unknown_layer_id,
                source_path: [:open_trade_transfer_package, :products, :pizza, :circuitdata, :processes, 0, :function_attributes, :layer_stop],
              },

            ]
          )
        end
      end
    end
  end
end
