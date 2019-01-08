require "spec_helper"

RSpec.describe Circuitdata::Schema do
  subject { Circuitdata::Schema }

  describe ".layer_kinds" do
    it "returns the layer kinds" do
      kinds = subject.layer_kinds
      expect(kinds).to be_a(Array)
      expect(kinds.sort).to eql(kinds)
      expect(kinds.first).to eql("adhesive")
    end
  end

  describe ".process_kinds" do
    it "returns the process kinds" do
      kinds = subject.process_kinds
      expect(kinds).to be_a(Array)
      expect(kinds.sort).to eql(kinds)
      expect(kinds.first).to eql("coin_attachment")
    end
  end

  describe ".product_questions" do
    let(:section_count_question) {
      {
        :id => "sections/name",
        :code => "name",
        :name => "Name",
        :description => "",
        :default => {
          :schema => {
            :type => "string",
          },
          :path => "/open_trade_transfer_package/products/.*/circuitdata/sections/name",
        },
        :uom => nil,
        :enforced => {
          :schema => {:type => "string"},
          :path => "/open_trade_transfer_package/products/.*/circuitdata/sections/name",
        },
        :restricted => {
          :schema => {:type => "string"},
          :path => "/open_trade_transfer_package/products/.*/circuitdata/sections/name",
        },
      }
    }

    it "generates the correct structure for sections" do
      section_question = subject.product_questions.first
      expect(section_question).to include(
        :id => "sections",
        :name => "Sections",
        :array? => true,
      )
      count_question = section_question[:questions].first
      expect(count_question).to eql(section_count_question)
    end

    it "generates the correct structure for configuration" do
      config_question = subject.product_questions.find { |question| question[:id] == "configuration" }
      expect(config_question).to include(
        :id => "configuration",
        :name => "Configuration",
        :array? => false,
      )
      stackup_question = config_question[:questions].first
      expect(stackup_question).to include(
        :id => "configuration/stackup",
        :name => "Stackup",
      )
      locked_question = stackup_question[:questions].first
      expect(locked_question).to include(
        id: "configuration/stackup/locked",
        code: "locked",
        name: "Locked",
        default: {:schema => {:type => "boolean"}, :path => "/open_trade_transfer_package/products/.*/circuitdata/configuration/stackup/locked"},
      )
    end

    it "generates the same result with and without caching" do
      uncached = JSON.parse(
        JSON.generate(subject.product_questions(cached: false)),
        symbolize_names: true,
      )
      cached = subject.product_questions
      expect(cached).to eql(uncached)
    end
  end

  describe ".profile_questions" do
    it "generates the same result with and without caching" do
      uncached = JSON.parse(
        JSON.generate(subject.profile_questions(cached: false)),
        symbolize_names: true,
      )
      cached = subject.profile_questions
      expect(cached).to eql(uncached)
    end

    context "question matches expected structure" do
      let(:expected_structure) {
        {
          :id => "sections",
          :name => "Sections",
          :array? => false,
          :questions => [
            {
              :id => "sections/count",
              :code => "count",
              :name => "Count",
              :description => "",
              :default => {
                :schema => {
                  :type => "integer",
                },
                :path => "/open_trade_transfer_package/profiles/default/circuitdata/sections/count",
              },
              :uom => nil,
              :enforced => {
                :schema => {:type => "integer"},
                :path => "/open_trade_transfer_package/profiles/enforced/circuitdata/sections/count",
              },
              :restricted => {
                :schema => {:type => "integer"},
                :path => "/open_trade_transfer_package/profiles/restricted/circuitdata/sections/count",
              },
            },
            {
              :id => "sections/mm2",
              :code => "mm2",
              :name => "Mm2",
              :description => "",
              :default => {
                :schema => {:type => "number"},
                :path => "/open_trade_transfer_package/profiles/default/circuitdata/sections/mm2",
              },
              :uom => nil,
              :enforced => {
                :schema => {:type => "number"},
                :path => "/open_trade_transfer_package/profiles/enforced/circuitdata/sections/mm2",
              },
              :restricted => {
                :schema => {:type => "number"},
                :path => "/open_trade_transfer_package/profiles/restricted/circuitdata/sections/mm2",
              },
            },
          ],
        }
      }

      it "returns the correct structure" do
        result = subject.profile_questions.first
        expect(result.except(:questions)).to eql(expected_structure.except(:questions))
        e_qs = expected_structure.fetch(:questions)
        r_qs = result.fetch(:questions)
        expect(r_qs.first).to eql(e_qs.first)
        expect(r_qs.second).to eql(e_qs.second)
      end

      it "does not have any nested objects" do
        result = JSON.generate(subject.profile_questions)
        expect(result).not_to include('"type":"object"')
      end
    end
  end
end
