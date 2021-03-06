module Circuitdata
  # SHOULD ONLY HOUSE COMMON FUNCTIONS ONLY

  require "active_support/all"
  require_relative "./circuitdata/version"
  require_relative "./circuitdata/json_schema"
  require_relative "./circuitdata/dereferencer"
  require_relative "./circuitdata/profile"
  require_relative "./circuitdata/schema"
  require_relative "./circuitdata/product"
  require_relative "./circuitdata/validator"
  require_relative "./circuitdata/json_validator"
  require_relative "./circuitdata/material_validator"
  require_relative "./circuitdata/product_id_validator"
  require_relative "./circuitdata/bury/bury"
  require_relative "./circuitdata/product_id_validator"
  require_relative "./circuitdata/exposed_area"
  require_relative "./circuitdata/summary"

  SCHEMA_BASE_PATH = File.join(__dir__, "circuitdata/schema_files/current")
  SCHEMA_FULL_PATH = File.join(SCHEMA_BASE_PATH, "..", "schema_current_dereferenced.json")
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
