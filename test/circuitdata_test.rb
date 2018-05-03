require "minitest/autorun"
require "byebug"
require "hashdiff"
require "pp"
require_relative "../lib/circuitdata"

class CircuitdataTest < Minitest::Test
  FIXTURE_BASE_PATH = File.join(__dir__, "test_data")

  def json_fixture(*path)
    path = path.map(&:to_s)
    file_path = File.join(FIXTURE_BASE_PATH, *path) + ".json"
    data = File.read(file_path)
    JSON.parse(data, symbolize_names: true)
  end

  def assert_hash_eql(expected, actual)
    diff = ::HashDiff.diff(expected, actual)
    if diff.empty?
      pass("Hashes are equal")
    else
      out = StringIO.new
      out.puts "Expected"
      out.puts "--------"
      out.puts expected.pretty_inspect

      out.puts
      out.puts "Actual"
      out.puts "------"
      out.puts actual.pretty_inspect
      out.puts

      grouped = diff.group_by(&:first)
      if grouped["~"]
        out.puts "\nDifferent Values (left, right):"
        grouped["~"].each do |(_, field, left, right)|
          out.puts "\t#{field}: '#{left.inspect}', '#{right.inspect}'"
        end
      end

      if grouped["-"]
        out.puts "\nMissing Values from right (left):"
        grouped["-"].each do |(_, field, left)|
          out.puts "\t#{field}: '#{left.inspect}'"
        end
      end

      if grouped["+"]
        out.puts "\nMissing Values from left (right):"
        grouped["+"].each do |(_, field, right)|
          out.puts "\t#{field}: '#{right.inspect}'"
        end
      end

      out.rewind
      flunk("Hashes are not equal:\n\n#{out.read}")
    end
  end
end
