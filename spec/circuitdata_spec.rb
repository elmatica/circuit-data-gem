require "spec_helper"

RSpec.describe Circuitdata do
  subject { Circuitdata }

  describe ".dereferenced_schema" do
    it 'does not include any references to "$ref"' do
      data = subject.dereferenced_schema
      expect(JSON.generate(data)).not_to include("$ref")
    end
  end
end
