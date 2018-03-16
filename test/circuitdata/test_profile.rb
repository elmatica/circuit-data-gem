require_relative "../circuitdata_test"

class CircuitdataProfileSchemaTest < CircuitdataTest
  def test_profile_questions
    exp = {
      :id => :sections,
      :name => "Sections",
      :array? => false,
      :questions => [
        {
          :id => "sections_count",
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
          :id => "sections_mm2",
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

    result = Circuitdata::Profile.questions.first
    assert_hash_eql exp.except(:questions), result.except(:questions)
    e_qs = exp.fetch(:questions)
    r_qs = result.fetch(:questions)
    assert_equal e_qs.first, r_qs.first
    assert_equal e_qs.second, r_qs.second
  end

  def test_profile_questions_no_stub
    question_sections = Circuitdata::Profile.questions
    non_matching_defaults_paths = []

    question_sections.each do |section|
      section[:questions].each do |question|
        defaults = question[:defaults]
        enforced = question[:enforced]
        both_present = !(defaults.nil? || enforced.nil?)
        if both_present && defaults[:descriptor] != enforced[:descriptor]
          non_matching_defaults_paths << defaults[:path]
        end
      end
    end

    assert_equal [], non_matching_defaults_paths
  end
end
