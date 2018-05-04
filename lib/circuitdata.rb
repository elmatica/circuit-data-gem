module Circuitdata
  # SHOULD ONLY HOUSE COMMON FUNCTIONS ONLY

  require "active_support/all"
  require "json-schema"
  require_relative "./circuitdata/version"
  require_relative "./circuitdata/dereferencer"
  require_relative "./circuitdata/profile"
  require_relative "./circuitdata/schema"
  require_relative "./circuitdata/product"
  require_relative "./circuitdata/validator"

  SCHEMA_BASE_PATH = File.join(__dir__, "circuitdata/schema_files/v1")
  SCHEMA_FULL_PATH = File.join(SCHEMA_BASE_PATH, "..", "schema_v1_dereferenced.json")
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
end
