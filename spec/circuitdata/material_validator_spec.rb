require "spec_helper"

RSpec.describe Circuitdata::MaterialValidator do
  subject { Circuitdata::MaterialValidator.new(material) }

  let(:material) { json_fixture(:material) }

  it "validates materials" do
    expect(subject).to be_valid
    expect(subject.errors).to eql([])
  end
end
