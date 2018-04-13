module Circuitdata
  # SHOULD ONLY HOUSE COMMON FUNCTIONS ONLY
  require "active_support/all"
  require "json-schema"
  require_relative "./circuitdata/file_comparer"
  require_relative "./circuitdata/compatibility_checker"
  require_relative "./circuitdata/dereferencer"
  require_relative "./circuitdata/profile"
  require_relative "./circuitdata/tools"

  SCHEMA_BASE_PATH = File.join(__dir__, "circuitdata/schema_files/v1")
  SCHEMA_FULL_PATH = File.join(SCHEMA_BASE_PATH, "ottp_circuitdata_schema.json")
  DEFINITIONS_FULL_PATH = File.join(
    SCHEMA_BASE_PATH, 'ottp_circuitdata_schema_definitions.json'
  )

  def self.get_data_summary(data)
    types = []
    wrapper = data&.dig(:open_trade_transfer_package)
    types << 'profile_restricted' unless wrapper&.dig(:profiles, :restricted).nil?
    types << 'profile_enforced' unless wrapper&.dig(:profiles, :enforced).nil?
    types << 'profile_defaults' unless wrapper&.dig(:profiles, :defaults).nil?
    types << 'capabilities' unless wrapper&.dig(:capabilities).nil?

    products = wrapper&.dig(:products)
    product_names = products.nil? ? [] : products.keys # this will return all the product names
    types << 'product' if product_names.any?
    # loop through the products
    products.each do |k, v|
      if v&.dig(:stackup, :specification_level) == 'specified' && !v&.dig(:stackup, :specification_level, :specified).nil?
        types << 'stackup'
      end
    end unless products.nil?

    return product_names, types
  end

  def self.read_json!(file)
    error, message, data = read_json(file)
    fail StandardError, message if error
    data
  end

  def self.read_json(file)
    error, message, data = false, nil, nil

    if file.is_a? Hash
      begin
        data = file
        data.deep_symbolize_keys!
      rescue
        error = true
        message = "Could not convert the Hash into JSON"
      end
    else
      begin
        open(file) do |f|
          data = JSON.parse(f.read, symbolize_names: true)
        end
      rescue
        error = true
        message = "Could not read the file"
      end
    end
    return error, message, data
  end

  def self.validate(content, schema_file_path: SCHEMA_FULL_PATH)
    error, message, validations_errors = false, nil, {}

    begin
      validated = JSON::Validator.fully_validate(schema_file_path, content, :errors_as_objects => true)
    rescue JSON::Schema::ReadFailed
      error = true
      message = "Could not read the validating schema"
    rescue JSON::Schema::SchemaError
      error = true
      message = "There is something was wrong with the validating schema"
    end
    unless error
      if validated.count > 0
        error = true
        message = "Could not validate the file against the CircuitData json schema"
        validated.each do |val_error|
          validations_errors[val_error[:fragment]] = [] unless validations_errors.has_key? val_error[:fragment]
          begin
            keep = val_error[:message].match("^(The\\sproperty\\s\\'[\\s\\S]*\\'\\s)([\\s\\S]*)(\\sin\\sschema\\sfile[\\s\\S]*)$").captures[1]
          rescue
            keep = val_error[:message]
          end
          validations_errors[val_error[:fragment]] << keep
        end
      end
    end
    return error, message, validations_errors
  end

  def self.schema(schema_file_path: SCHEMA_FULL_PATH)
    JSON.parse(
      File.read(schema_file_path),
      symbolize_names: true
    )
  end

  def self.dereferenced_schema(schema_file_path: SCHEMA_FULL_PATH)
    Dereferencer.dereference(
      schema(schema_file_path: schema_file_path),
      File.dirname(schema_file_path)
    )
  end

  def self.compare_files(file_hash)
    comparer = FileComparer.new(file_hash)
    comparer.compare
  end

  def self.compatibility_checker(product_file, check_file=nil, validate_origins=false, schema_file_path: SCHEMA_FULL_PATH, definitions_file_path: DEFINITIONS_FULL_PATH)
    schema = read_json!(schema_file_path)
    definitions = read_json!(definitions_file_path)
    docu = Tools.new(schema, definitions)
    checker = CompatibilityChecker.new(product_file, check_file, validate_origins, docu)
    checker.start_check
  end

  def self.create_documentation(schema_file_path: SCHEMA_FULL_PATH, definitions_file_path: DEFINITIONS_FULL_PATH)
    schema = read_json!(schema_file_path)
    definitions = read_json!(definitions_file_path)
    docu = Tools.new(schema, definitions)
    ra = docu.create_structure
    docu.create_documentation(ra)
  end

  def self.test
    product1 = File.join(File.dirname(__FILE__), '../test/test_data/test_product1.json')
    product2 = File.join(File.dirname(__FILE__), '../test/test_data/test_product2.json')
    profile_restricted = File.join(File.dirname(__FILE__), '../test/test_data/testfile-profile-restricted.json')
    profile_enforced = File.join(File.dirname(__FILE__), '../test/test_data/testfile-profile-enforced.json')
    profile_default = File.join(File.dirname(__FILE__), '../test/test_data/testfile-profile-default.json')
    capabilities = File.join(File.dirname(__FILE__), '../test/test_data/testfile-capability.json')

    # THEN TEST THE COMPARE FILES:
    puts "Testing file comparison"
    file_hash = {product1: product1, product2: product2, restricted: profile_restricted, enforced: profile_enforced, default: profile_default, capability: capabilities}
    Circuitdata.compare_files(file_hash, true)
  end
end
