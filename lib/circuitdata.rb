module Circuitdata 
  # SHOULD ONLY HOUSE COMMON FUNCTIONS ONLY
  require 'active_support/all'
  require 'circuitdata/file_comparer'
  require 'circuitdata/compatibility_checker'

  def self.read_json(content)
    require 'open-uri'
    require 'json'

    error = false
    message = ""
    returncontent = nil
    if content.is_a? Hash
      begin
        returncontent = content
        returncontent.deep_symbolize_keys!
      rescue
        error = true
        message = "Could not convert the Hash into JSON"
      end
    else
      begin
        open(content) do |f|
          returncontent = JSON.parse(f.read, symbolize_names: true)
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
