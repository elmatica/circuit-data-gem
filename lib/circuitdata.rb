module Circuitdata 
  # SHOULD ONLY HOUSE COMMON FUNCTIONS ONLY
  require 'active_support/all'
  require 'circuitdata/file_comparer'
  require 'circuitdata/compatibility_checker'

  def self.get_data_summary(data)
    types = []
    wrapper = data&.dig(:open_trade_transfer_package)
    types << 'profile_enforced' unless wrapper&.dig(:profiles, :enforced).nil?
    types << 'profile_restricted' unless wrapper&.dig(:profiles, :restricted).nil?
    types << 'profile_defaults' unless wrapper&.dig(:profiles, :defaults).nil?
    types << 'capabilities' unless wrapper&.dig(:capabilities).nil?

    products = wrapper&.dig(:products)
    product_names = products.nil? ? [] : products.keys# this will return all the product names
    # loop through the products
    products.each do |k, v|
      if v&.dig(:stackup, :specification_level) == 'specified' && !v&.dig(:stackup, :specification_level, :specified).nil?
        types << 'stackup'
      end
    end unless products.nil?

    # return (product_names.uniq rescue []), types
    return product_names, types
  end

  def self.read_json(file)
    require 'json'
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

  def self.validate(content)
    require 'json-schema'

    # schema_path = File.join(File.dirname(__FILE__), 'circuitdata/schema_files/v1/ottp_circuitdata_schema.json')
    # schema = File.read(schema_path)
    $jsonschema_v1 = 'http://schema.circuitdata.org/v1/ottp_circuitdata_schema.json'

    error = false
    message = ""
    validationserrors = {}

    begin
      validated = JSON::Validator.fully_validate($jsonschema_v1, content, :errors_as_objects => true)
    rescue JSON::Schema::ReadFailed
      errors = true
      message = "Could not read the schema #{$jsonschema_v1}"
    rescue JSON::Schema::SchemaError
      errors = true
      message = "Something was wrong with the schema #{$jsonschema_v1}"
    end
    unless errors
      if validated.count > 0
        error = true
        message = "Could not validate the file against the CircuitData json schema"
        validated.each do |valerror|
          validationserrors[valerror[:fragment]] = [] unless validationserrors.has_key? valerror[:fragment]
          begin
            keep = valerror[:message].match("^(The\\sproperty\\s\\'[\\s\\S]*\\'\\s)([\\s\\S]*)(\\sin\\sschema\\sfile[\\s\\S]*)$").captures[1]
          rescue
            keep = valerror[:message]
          end
          validationserrors[valerror[:fragment]] << keep
        end
      end
    end
    return error, message, validationserrors
  end

  def self.compare_files(filehash, validate_origins=false)
    comparer = FileComparer.new(filehash, validate_origins)
    comparer.compare
  end

  def self.compatibility_checker(product_file, check_file=nil, validate_origins=false)
    checker = CompatibilityChecker.new(product_file, check_file, validate_origins)
    checker.start_check
  end

  def self.bk_checker(product_file, check_file=nil, validate_origins=true)
    checker = BkChecker.new(product_file, check_file, validate_origins)
    checker.start_check
  end

  def self.test
    wrong_path= 'testfile-product.json'
    pass_product = File.join(File.dirname(__FILE__), '../test/test_data/pass_product.json')
    fail_product = File.join(File.dirname(__FILE__), '../test/test_data/fail_product.json')
    pass_restricted = File.join(File.dirname(__FILE__), '../test/test_data/pass_profile_restricted.json')
    fail_restricted = File.join(File.dirname(__FILE__), '../test/test_data/fail_profile_restricted.json')
    pass_enforced = File.join(File.dirname(__FILE__), '../test/test_data/pass_profile_enforced.json')
    fail_enforced = File.join(File.dirname(__FILE__), '../test/test_data/fail_profile_enforced.json')
    pass_capabilities = File.join(File.dirname(__FILE__), '../test/test_data/pass_capabilities.json')
    fail_capabilities = File.join(File.dirname(__FILE__), '../test/test_data/fail_capabilities.json')

    Circuitdata.compatibility_checker(wrong_path)
    Circuitdata.compatibility_checker(pass_product)
    Circuitdata.compatibility_checker(fail_product)
    Circuitdata.compatibility_checker(pass_product, pass_restricted)
    Circuitdata.compatibility_checker(pass_product, fail_restricted)
    Circuitdata.compatibility_checker(pass_product, pass_enforced)
    Circuitdata.compatibility_checker(pass_product, fail_enforced)
    Circuitdata.compatibility_checker(pass_product, pass_capabilities)
    Circuitdata.compatibility_checker(pass_product, fail_capabilities)
  end
end
