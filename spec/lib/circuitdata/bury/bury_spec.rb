require "spec_helper"

RSpec.describe Circuitdata::Bury do
  subject { described_class }

  describe ".bury" do
    let(:value) { "pizza" }

    it "buries a simple list of strings" do
      path = ["a", "b"]
      expect(subject.bury({}, *path, value)).to eql({"a" => {"b" => "pizza"}})
    end

    it "buries a simple list of strings and integers" do
      path = ["a", "b", 0, "c"]
      expect(subject.bury({}, *path, value)).to eql({
        "a" => {"b" => [{"c" => "pizza"}]},
      })
    end

    it "buries a list with hashes" do
      path = ["a", {"b" => "c"}, "d"]
      expect(subject.bury({}, *path, value)).to eql({
        "a" => [{"b" => "c", "d" => "pizza"}],
      })
    end

    it "updates an existing value with a list containing hashes" do
      path = ["a", {"b" => "c"}, "d"]
      result = subject.bury({}, *path, value)

      expect(subject.bury(result, *path, "chips")).to eql({
        "a" => [{"b" => "c", "d" => "chips"}],
      })
    end

    it "raises an error if hash parent is not an array" do
      path = ["a", {"b" => "c"}, "d"]
      data = {"a" => {"b" => "c", "d" => "chips"}}

      expect {
        subject.bury(data, *path, value)
      }.to raise_error(
        Circuitdata::Bury::InvalidDataError,
        'parent of {"b"=>"c"} is not an array'
      )
    end
  end

  describe ".dig" do
    it "returns nil if not present" do
      path = ["a", "c"]
      expect(subject.dig({"a" => {"b" => "pizza"}}, *path)).to eql(nil)
    end

    it "returns value for string path" do
      path = ["a", "b"]
      expect(subject.dig({"a" => {"b" => "pizza"}}, *path)).to eql("pizza")
    end

    it "returns value for path with list of strings and integers" do
      data = {"a" => {"b" => [{"c" => "pizza"}]}}
      path = ["a", "b", 0, "c"]
      expect(subject.dig(data, *path)).to eql("pizza")
    end

    it "returns value for path with hashes" do
      data = {"a" => [{"b" => "c", "d" => "pizza"}]}
      path = ["a", {"b" => "c"}, "d"]
      expect(subject.dig(data, *path)).to eql("pizza")
    end
  end
end
