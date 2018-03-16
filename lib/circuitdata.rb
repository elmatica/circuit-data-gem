module Circuitdata
  # SHOULD ONLY HOUSE COMMON FUNCTIONS ONLY

  require "active_support/all"
  require "json-schema"
  require_relative "./circuitdata/version"
  require_relative "./circuitdata/dereferencer"
  require_relative "./circuitdata/profile"
  require_relative "./circuitdata/schema"
  require_relative "./circuitdata/product"

  SCHEMA_BASE_PATH = File.join(__dir__, "circuitdata/schema_files/v1")
  SCHEMA_FULL_PATH = File.join(SCHEMA_BASE_PATH, "ottp_circuitdata_schema.json")
  DEFINITIONS_FULL_PATH = File.join(
    SCHEMA_BASE_PATH, "ottp_circuitdata_schema_definitions.json"
  )
  def self.dereferenced_schema(schema_file_path: SCHEMA_FULL_PATH)
    schema_cache[schema_file_path] ||= Dereferencer.dereference(
      schema(schema_file_path: schema_file_path),
      File.dirname(schema_file_path)
    )
  end

  private

  def self.schema(schema_file_path: SCHEMA_FULL_PATH)
    JSON.parse(
      File.read(schema_file_path),
      symbolize_names: true,
    )
  end

  def self.schema_cache
    @schema_cache ||= {}
  end

  # def self.test
  #   product1 = File.join(File.dirname(__FILE__), '../test/test_data/test_product1.json')
  #   product2 = File.join(File.dirname(__FILE__), '../test/test_data/test_product2.json')
  #   profile_restricted = File.join(File.dirname(__FILE__), '../test/test_data/testfile-profile-restricted.json')
  #   profile_enforced = File.join(File.dirname(__FILE__), '../test/test_data/testfile-profile-enforced.json')
  #   profile_default = File.join(File.dirname(__FILE__), '../test/test_data/testfile-profile-default.json')
  #   capabilities = File.join(File.dirname(__FILE__), '../test/test_data/testfile-capability.json')

  #   # THEN TEST THE COMPARE FILES:
  #   puts "Testing file comparison"
  #   file_hash = {product1: product1, product2: product2, restricted: profile_restricted, enforced: profile_enforced, default: profile_default, capability: capabilities}
  #   Circuitdata.compare_files(file_hash, true)
  # end
end
