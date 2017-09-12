module Circuitdata
  require 'active_support/all'
  require 'circuitdata/file_comparer'
  require 'circuitdata/compatibility_checker'

  def self.content(checksjson)
    number_of_products = 0
    stackup =  false
    profile_defaults = false
    profile_enforced = false
    profile_restricted = false
    capabilities = false
    productname = nil
    checksjson.deep_symbolize_keys!
    if checksjson.has_key? :open_trade_transfer_package
      if checksjson[:open_trade_transfer_package].has_key? :products
        if checksjson[:open_trade_transfer_package][:products].length > 0
          number_of_products = checksjson[:open_trade_transfer_package][:products].length
          checksjson[:open_trade_transfer_package][:products].each do |key, value|
            productname = key.to_s
            if checksjson[:open_trade_transfer_package][:products][key].has_key? :stackup
              if checksjson[:open_trade_transfer_package][:products][key][:stackup].has_key? :specification_level
                if checksjson[:open_trade_transfer_package][:products][key][:stackup][:specification_level] == :specified
                  if checksjson[:open_trade_transfer_package][:products][key][:stackup].has_key? :specified
                    if checksjson[:open_trade_transfer_package][:products][key][:stackup][:specified].length > 0
                      stackup = true
                    end
                  end
                end
              end
            end
          end
        end
      end
      if checksjson[:open_trade_transfer_package].has_key? :profiles
        if checksjson[:open_trade_transfer_package][:profiles].has_key? :enforced
          if checksjson[:open_trade_transfer_package][:profiles][:enforced].length > 0
            profile_enforced = true
          end
        end
        if checksjson[:open_trade_transfer_package][:profiles].has_key? :restricted
          if checksjson[:open_trade_transfer_package][:profiles][:restricted].length > 0
            profile_restricted = true
          end
        end
        if checksjson[:open_trade_transfer_package][:profiles].has_key? :defaults
          if checksjson[:open_trade_transfer_package][:profiles][:defaults].length > 0
            profile_defaults = true
          end
        end
      end
      if checksjson[:open_trade_transfer_package].has_key? :capabilities
        if checksjson[:open_trade_transfer_package][:capabilities].length > 0
          capabilities = true
        end
      end
    end
    return number_of_products, stackup, profile_defaults, profile_restricted, profile_enforced, capabilities, productname
  end

  def self.read_json(content)
    require 'open-uri'
    require 'json'

    error = false
    message = ""
    returncontent = nil
    if content.is_a? Hash
      begin
        returncontent = content
      rescue
        error = true
        message = "Could not convert the Hash into JSON"
      end
    else
      begin
        open(content) do |f|
          returncontent = JSON.parse(f.read)
        end
      rescue
        error = true
        message = "Could not read the file"
      end
    end
    return error, message, returncontent
  end

  def self.validate(content)
    require 'json-schema'
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

  def self.compatibility_checker(productfile, checksfile=nil, validate_origins=true)
    checker = CompatibilityChecker.new(productfile, checksfile, validate_origins)
    checker.start_check
  end
end
