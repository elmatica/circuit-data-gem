module FixtureHelpers
  FIXTURE_BASE_PATH = File.join(__dir__, "..", "test_data")

  def json_fixture(*path)
    path = path.map(&:to_s)
    file_path = File.join(FIXTURE_BASE_PATH, *path) + ".json"
    data = File.read(file_path)
    JSON.parse(data, symbolize_names: true)
  end
end
