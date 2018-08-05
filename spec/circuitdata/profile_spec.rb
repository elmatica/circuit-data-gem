require "spec_helper"

RSpec.describe Circuitdata::Profile do
  subject { described_class }

  describe ".questions" do
    context "question matches expected structure" do
      let(:expected_structure) {
        {
          :id => :sections,
          :name => "Sections",
          :array? => false,
          :questions => [
            {
              :id => :"sections/count",
              :code => :count,
              :name => "Count",
              :description => "",
              :defaults => {
                :schema => {
                  :type => "integer",
                },
                :path => "/open_trade_transfer_package/profiles/defaults/circuitdata/sections/count",
              },
              :uom => nil,
              :required => {
                :schema => {:type => "integer"},
                :path => "/open_trade_transfer_package/profiles/required/circuitdata/sections/count",
              },
              :forbidden => {
                :schema => {:type => "integer"},
                :path => "/open_trade_transfer_package/profiles/forbidden/circuitdata/sections/count",
              },
            },
            {
              :id => :"sections/mm2",
              :code => :mm2,
              :name => "Mm2",
              :description => "",
              :defaults => {
                :schema => {:type => "number"},
                :path => "/open_trade_transfer_package/profiles/defaults/circuitdata/sections/mm2",
              },
              :uom => nil,
              :required => {
                :schema => {:type => "number"},
                :path => "/open_trade_transfer_package/profiles/required/circuitdata/sections/mm2",
              },
              :forbidden => {
                :schema => {:type => "number"},
                :path => "/open_trade_transfer_package/profiles/forbidden/circuitdata/sections/mm2",
              },
            },
          ],
        }
      }

      it "returns the correct structure" do
        result = subject.questions.first
        expect(result.except(:questions)).to eql(expected_structure.except(:questions))
        e_qs = expected_structure.fetch(:questions)
        r_qs = result.fetch(:questions)
        expect(r_qs.first).to eql(e_qs.first)
        expect(r_qs.second).to eql(e_qs.second)
      end

      it "does not have any nested objects" do
        result = JSON.generate(subject.questions)
        expect(result).not_to include('"type":"object"')
      end
    end
  end
end
