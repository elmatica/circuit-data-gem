module Circuitdata


  def self.content(checksjson)
    number_of_products = 0
    stackup =  false
    profile_defaults = false
    profile_enforced = false
    profile_restricted = false
    capabilities = false
    productname = nil
    if checksjson.has_key? "open_trade_transfer_package"
      if checksjson["open_trade_transfer_package"].has_key? "products"
        if checksjson["open_trade_transfer_package"]["products"].length > 0
          number_of_products = checksjson["open_trade_transfer_package"]["products"].length
          checksjson["open_trade_transfer_package"]["products"].each do |key, value|
            productname = key.to_s
            if checksjson["open_trade_transfer_package"]["products"][key].has_key? "stackup"
              if checksjson["open_trade_transfer_package"]["products"][key]["stackup"].has_key? "specification_level"
                if checksjson["open_trade_transfer_package"]["products"][key]["stackup"]["specification_level"] == "specified"
                  if checksjson["open_trade_transfer_package"]["products"][key]["stackup"].has_key? "specified"
                    if checksjson["open_trade_transfer_package"]["products"][key]["stackup"]["specified"].length > 0
                      stackup = true
                    end
                  end
                end
              end
            end
          end
        end
      end
      if checksjson["open_trade_transfer_package"].has_key? "profiles"
        if checksjson["open_trade_transfer_package"]["profiles"].has_key? "enforced"
          if checksjson["open_trade_transfer_package"]["profiles"]["enforced"].length > 0
            profile_enforced = true
          end
        end
        if checksjson["open_trade_transfer_package"]["profiles"].has_key? "restricted"
          if checksjson["open_trade_transfer_package"]["profiles"]["restricted"].length > 0
            profile_restricted = true
          end
        end
        if checksjson["open_trade_transfer_package"]["profiles"].has_key? "defaults"
          if checksjson["open_trade_transfer_package"]["profiles"]["defaults"].length > 0
            profile_defaults = true
          end
        end
      end
      if checksjson["open_trade_transfer_package"].has_key? "capabilities"
        if checksjson["open_trade_transfer_package"]["capabilities"].length > 0
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
            scrap, keep, scrap2 = valerror[:message].match("^(The\\sproperty\\s\\'[\\s\\S]*\\'\\s)([\\s\\S]*)(\\sin\\sschema\\sfile[\\s\\S]*)$").captures
          rescue
            keep = valerror[:message]
          end
          validationserrors[valerror[:fragment]] << keep
        end
      end
    end
    return error, message, validationserrors
  end

  def self.compare_files(filearray, validate_origins=false)
    # Prepare the return
    ra = {
      error: false,
      errormessage: "",
      summary: {},
      conflicts: {},
      product: nil,
      layers: [],
    }
    totalproducts = 0
    productjson = {}
    productfile = ""
    if not filearray.is_a? Hash
      ra[:error] = true
      ra[:errormessage] = "You have to feed this function with a hash of names and hashes"
      return ra
    end

    # Do preliminary tests
    filearray.each do |key, value|
      error, message, returncontent = self.read_json(value)
      if error
        ra[:error] = true
        ra[:errormessage] = "Could not read the value in key #{key} (#{value})"
        ra[:summary] = {}
        ra[:conflicts] = {}
        return ra
      end
      if validate_origins
        ra[:error], ra[:errormessage], validationserrors = self.validate(returncontent)
        if ra[:error]
          ra[:summary] = {}
          ra[:conflicts] = {}
          return ra
        end
      end

      products, stackup, profile_default, profile_restricted, profile_enforced, capabilities, product = self.content(returncontent)
      if ra[:product].nil?
        ra[:product] = product unless product.nil?
        totalproducts += 1
      else
        totalproducts += products if product != ra[:product]
      end
      if totalproducts > 1
        ra[:error] = true
        ra[:errormessage] = "There are more than one product amongst you files"
        ra[:summary] = {}
        ra[:conflicts] = {}
        return ra
      end
      if products == 1
        productjson = returncontent
        productfile = key.to_s
      end
      ra[:layers] << key.to_s
    end

    # Populate the summary
    ra[:summary] = productjson["open_trade_transfer_package"]["products"][ra[:product]]["printed_circuits_fabrication_data"]

    # Do comparisons
    filearray.each do |key, value|
      unless key.to_s == productfile
        #puts self.compatibility_checker( productjson, value, false )
      end
    end
    puts JSON.pretty_generate(ra)
    return ra
  end

  def self.compatibility_checker( productfile, checksfile=nil, validate_origins=true )

    require 'open-uri'
    require 'json'
    require 'json-schema'

    $jsonschema_v1 = 'http://schema.circuitdata.org/v1/ottp_circuitdata_schema.json'

    # prepare the return
    returnarray = {
      error: false,
      errormessage: "",
      validationserrors: {},
      restrictederrors: {},
      enforcederrors: {},
      capabilitieserrors: {},
      contains: {
        file1: {
          products: 0,
          stackup: false,
          profile_defaults: false,
          profile_enforced: false,
          profile_restricted: false,
          capabilities: false
        },
        file2: {
          products: 0,
          stackup: false,
          profile_defaults: false,
          profile_enforced: false,
          profile_restricted: false,
          capabilities: false
        }
      }
    }

    # Check the files or hashes
    #
    returnarray[:error], returnarray[:errormessage], json_productfile = self.read_json(productfile)
    return returnarray if returnarray[:error]
    if not checksfile.nil?
      returnarray[:error], returnarray[:errormessage], json_checksfile = self.read_json(checksfile)
      return returnarray if returnarray[:error]
    end

    # Validate the original files against the CircuitData schema
    if validate_origins
      returnarray[:error], returnarray[:errormessage], returnarray[:validationserrors] = self.validate(json_productfile)
      return returnarray if returnarray[:error]
      if not checksfile.nil?
        returnarray[:error], returnarray[:errormessage], returnarray[:validationserrors] = self.validate(json_checksfile)
        return returnarray if returnarray[:error]
      end
    end

    # Check against the content
    returnarray[:contains][:file1][:products], returnarray[:contains][:file1][:stackup], returnarray[:contains][:file1][:profile_defaults], returnarray[:contains][:file1][:profile_restricted], returnarray[:contains][:file1][:profile_enforced], returnarray[:contains][:file1][:capabilities], productname = self.content(json_productfile)
    if not checksfile.nil?
      returnarray[:contains][:file2][:products], returnarray[:contains][:file2][:stackup], returnarray[:contains][:file2][:profile_defaults], returnarray[:contains][:file2][:profile_restricted], returnarray[:contains][:file2][:profile_enforced], returnarray[:contains][:file2][:capabilities], productname = self.content(json_checksfile)
    end

    if not checksfile.nil?

      # Create the JSON
      restrictedschema = enforcedschema = capabilityschema = {
        "$schema": "http://json-schema.org/draft-04/schema#",
        "type": "object",
        "additionalProperties": false,
        "required": ["open_trade_transfer_package"],
        "properties": {
          "open_trade_transfer_package": {
            "type": "object",
            "properties": {
              "version": {
                "type": "string",
                "pattern": "^1.0$"
              },
              "information": {
                "$ref": "https://raw.githubusercontent.com/elmatica/Open-Trade-Transfer-Package/master/v1/ottp_schema_definitions.json#/definitions/information"
              },
              "products": {
                "type": "object",
                "properties": {
                  "generic": {
                    "type": "object",
                    "properties": {},
                    "id": "generic",
                    "description": "this should validate any element under generic to be valid"
                  }
                },
                "patternProperties": {
                  "^(?!generic$).*": {
                    "type": "object",
                    "required": ["printed_circuits_fabrication_data"],
                    "properties": {
                      "printed_circuits_fabrication_data": {
                        "type": "object",
                        "required": ["version"],
                        "properties": {
                          "stackup": {
                            "type": "object",
                            "properties": {
                              "specified": {
                                "type": "object",
                                "properties": {
                                }
                              }
                            }
                          }
                        }
                      }
                    }
                  }
                }
              }
            }
          }
        }
      }

      if returnarray[:contains][:file1][:products] > 0 or returnarray[:contains][:file1][:stackup]
        # RUN THROUGH THE ENFORCED
        if returnarray[:contains][:file2][:profile_enforced]
          json_checksfile["open_trade_transfer_package"]["profiles"]["enforced"]["printed_circuits_fabrication_data"].each do |key, value|
            if json_checksfile["open_trade_transfer_package"]["profiles"]["enforced"]["printed_circuits_fabrication_data"][key].is_a? Hash
              json_checksfile["open_trade_transfer_package"]["profiles"]["enforced"]["printed_circuits_fabrication_data"][key].each do |subkey, subvalue|
                enforcedschema[:properties][:open_trade_transfer_package][:properties][:products][:patternProperties][:"^(?!generic$).*"][:properties][:printed_circuits_fabrication_data][:properties][key.to_sym] = {:type => "object", :properties => {} } unless enforcedschema[:properties][:open_trade_transfer_package][:properties][:products][:patternProperties][:"^(?!generic$).*"][:properties][:printed_circuits_fabrication_data][:properties].has_key? key.to_sym
                enforcedschema[:properties][:open_trade_transfer_package][:properties][:products][:patternProperties][:"^(?!generic$).*"][:properties][:printed_circuits_fabrication_data][:properties][:stackup][:properties][:specified][:properties][key.to_sym] = {:type => "object", :properties => {} } unless enforcedschema[:properties][:open_trade_transfer_package][:properties][:products][:patternProperties][:"^(?!generic$).*"][:properties][:printed_circuits_fabrication_data][:properties][:stackup][:properties][:specified][:properties].has_key? key.to_sym
                if subvalue.is_a? String
                  if subvalue.match("^(\\d*|\\d*.\\d*)\\.\\.\\.(\\d*|\\d*.\\d*)$") #This is a value range
                    from, too = subvalue.match("^(\\d*|\\d*.\\d*)\\.\\.\\.(\\d*|\\d*.\\d*)$").captures
                    newhash = eval("{:minimum => #{from}, :maximum => #{too}}")
                    enforcedschema[:properties][:open_trade_transfer_package][:properties][:products][:patternProperties][:"^(?!generic$).*"][:properties][:printed_circuits_fabrication_data][:properties][key.to_sym][:properties][subkey.to_sym] = newhash
                    enforcedschema[:properties][:open_trade_transfer_package][:properties][:products][:patternProperties][:"^(?!generic$).*"][:properties][:printed_circuits_fabrication_data][:properties][:stackup][:properties][:specified][:properties][key.to_sym][:properties][subkey.to_sym] = newhash
                  else # This is a normal string - check for commas
                    enum = []
                    subvalue.split(',').each { |enumvalue| enum << enumvalue.strip }
                    enforcedschema[:properties][:open_trade_transfer_package][:properties][:products][:patternProperties][:"^(?!generic$).*"][:properties][:printed_circuits_fabrication_data][:properties][key.to_sym][:properties][subkey.to_sym] = eval("{:enum => #{enum}}")
                    enforcedschema[:properties][:open_trade_transfer_package][:properties][:products][:patternProperties][:"^(?!generic$).*"][:properties][:printed_circuits_fabrication_data][:properties][:stackup][:properties][:specified][:properties][key.to_sym][:properties][subkey.to_sym] = eval("{:enum => #{enum}}")
                  end
                elsif subvalue.is_a? Numeric # This is a normal string
                  enforcedschema[:properties][:open_trade_transfer_package][:properties][:products][:patternProperties][:"^(?!generic$).*"][:properties][:printed_circuits_fabrication_data][:properties][key.to_sym][:properties][subkey.to_sym] = eval("{:enum => [#{subvalue.to_s}]}")
                  enforcedschema[:properties][:open_trade_transfer_package][:properties][:products][:patternProperties][:"^(?!generic$).*"][:properties][:printed_circuits_fabrication_data][:properties][:stackup][:properties][:specified][:properties][key.to_sym][:properties][subkey.to_sym] = eval("{:enum => [#{subvalue.to_s}]}")
                end
              end
            end
          end
          begin
            enforcedvalidate = JSON::Validator.fully_validate(enforcedschema.to_json, json_productfile, :errors_as_objects => true)
          rescue JSON::Schema::ReadFailed
            $errors = true
            returnarray[:error] = true
            returnarray[:errormessage] = "Could not read the schema #{$jsonschema_v1}"
          rescue JSON::Schema::SchemaError
            $errors = true
            returnarray[:error] = true
            returnarray[:errormessage] = "Something was wrong with the schema #{$jsonschema_v1}"
          end
          unless $errors
            if enforcedvalidate.count > 0
              returnarray[:error] = true
              returnarray[:errormessage] = "The product to check did not meet the requirements"
              enforcedvalidate.each do |valerror|
                returnarray[:enforcederrors][valerror[:fragment]] = [] unless returnarray[:enforcederrors].has_key? valerror[:fragment]
                begin
                  scrap, keep, scrap2 = valerror[:message].match("^(The\\sproperty\\s\\'[\\s\\S]*\\'\\s)([\\s\\S]*)(\\sin\\sschema[\\s\\S]*)$").captures
                rescue
                  keep = valerror[:message]
                end
                returnarray[:enforcederrors][valerror[:fragment]] << keep
              end
            end
          end
        end
        # RUN THROUGH THE RESTRICTED
        if returnarray[:contains][:file2][:profile_restricted]
          json_checksfile["open_trade_transfer_package"]["profiles"]["restricted"]["printed_circuits_fabrication_data"].each do |key, value|
            if json_checksfile["open_trade_transfer_package"]["profiles"]["restricted"]["printed_circuits_fabrication_data"][key].is_a? Hash
              json_checksfile["open_trade_transfer_package"]["profiles"]["restricted"]["printed_circuits_fabrication_data"][key].each do |subkey, subvalue|
                restrictedschema[:properties][:open_trade_transfer_package][:properties][:products][:patternProperties][:"^(?!generic$).*"][:properties][:printed_circuits_fabrication_data][:properties][key.to_sym] = {:type => "object", :properties => {} } unless restrictedschema[:properties][:open_trade_transfer_package][:properties][:products][:patternProperties][:"^(?!generic$).*"][:properties][:printed_circuits_fabrication_data][:properties].has_key? key.to_sym
                restrictedschema[:properties][:open_trade_transfer_package][:properties][:products][:patternProperties][:"^(?!generic$).*"][:properties][:printed_circuits_fabrication_data][:properties][:stackup][:properties][:specified][:properties][key.to_sym] = {:type => "object", :properties => {} } unless restrictedschema[:properties][:open_trade_transfer_package][:properties][:products][:patternProperties][:"^(?!generic$).*"][:properties][:printed_circuits_fabrication_data][:properties][:stackup][:properties][:specified][:properties].has_key? key.to_sym
                if subvalue.is_a? String
                  if subvalue.match("^(\\d*|\\d*.\\d*)\\.\\.\\.(\\d*|\\d*.\\d*)$") #This is a value range
                    from, too = subvalue.match("^(\\d*|\\d*.\\d*)\\.\\.\\.(\\d*|\\d*.\\d*)$").captures
                    newhash = {:not => {:allOf => [{:minimum => from.to_f},{:maximum => too.to_f}]}}
                    restrictedschema[:properties][:open_trade_transfer_package][:properties][:products][:patternProperties][:"^(?!generic$).*"][:properties][:printed_circuits_fabrication_data][:properties][key.to_sym][:properties][subkey.to_sym] = newhash
                    restrictedschema[:properties][:open_trade_transfer_package][:properties][:products][:patternProperties][:"^(?!generic$).*"][:properties][:printed_circuits_fabrication_data][:properties][:stackup][:properties][:specified][:properties][key.to_sym][:properties][subkey.to_sym] = newhash
                  else # This is a normal string - check for commas
                    newhash = {:not => {:anyOf => [{ :enum => ""}]}}
                    enum = []
                    subvalue.split(',').each { |enumvalue| enum << enumvalue.strip }
                    newhash[:not][:anyOf][0][:enum] = enum
                    restrictedschema[:properties][:open_trade_transfer_package][:properties][:products][:patternProperties][:"^(?!generic$).*"][:properties][:printed_circuits_fabrication_data][:properties][key.to_sym][:properties][subkey.to_sym] = newhash
                    restrictedschema[:properties][:open_trade_transfer_package][:properties][:products][:patternProperties][:"^(?!generic$).*"][:properties][:printed_circuits_fabrication_data][:properties][:stackup][:properties][:specified][:properties][key.to_sym][:properties][subkey.to_sym] = newhash
                  end
                elsif subvalue.is_a? Numeric # This is a normal string
                  newhash = {:not => {:allOf => [{:minimum => subvalue.to_f},{:maximum => subvalue.to_f}]}}
                  restrictedschema[:properties][:open_trade_transfer_package][:properties][:products][:patternProperties][:"^(?!generic$).*"][:properties][:printed_circuits_fabrication_data][:properties][key.to_sym][:properties][subkey.to_sym] = newhash
                  restrictedschema[:properties][:open_trade_transfer_package][:properties][:products][:patternProperties][:"^(?!generic$).*"][:properties][:printed_circuits_fabrication_data][:properties][:stackup][:properties][:specified][:properties][key.to_sym][:properties][subkey.to_sym] = newhash
                end
              end
            end
          end
          begin
            restrictedvalidate = JSON::Validator.fully_validate(restrictedschema.to_json, json_productfile, :errors_as_objects => true)
          rescue JSON::Schema::ReadFailed
            $errors = true
            returnarray[:error] = true
            returnarray[:errormessage] = "Could not read the schema #{$jsonschema_v1}"
          rescue JSON::Schema::SchemaError
            $errors = true
            returnarray[:error] = true
            returnarray[:errormessage] = "Something was wrong with the schema #{$jsonschema_v1}"
          end
          unless $errors
            if restrictedvalidate.count > 0
              returnarray[:error] = true
              returnarray[:errormessage] = "The product to check did not meet the requirements"
              restrictedvalidate.each do |valerror|
                returnarray[:restrictederrors][valerror[:fragment]] = [] unless returnarray[:restrictederrors].has_key? valerror[:fragment]
                begin
                  scrap, keep, scrap2 = valerror[:message].match("^(The\\sproperty\\s\\'[\\s\\S]*\\'\\s)([\\s\\S]*)(\\sin\\sschema[\\s\\S]*)$").captures
                rescue
                  keep = valerror[:message]
                end
                returnarray[:restrictederrors][valerror[:fragment]] << keep
              end
            end
          end
        end
        # RUN THROUGH THE CAPABILITIES
        if returnarray[:contains][:file2][:capabilities]
          json_checksfile["open_trade_transfer_package"]["capabilities"]["printed_circuits_fabrication_data"].each do |key, value|
            if json_checksfile["open_trade_transfer_package"]["capabilities"]["printed_circuits_fabrication_data"][key].is_a? Hash
              json_checksfile["open_trade_transfer_package"]["capabilities"]["printed_circuits_fabrication_data"][key].each do |subkey, subvalue|
                capabilityschema[:properties][:open_trade_transfer_package][:properties][:products][:patternProperties][:"^(?!generic$).*"][:properties][:printed_circuits_fabrication_data][:properties][key.to_sym] = {:type => "object", :properties => {} } unless capabilityschema[:properties][:open_trade_transfer_package][:properties][:products][:patternProperties][:"^(?!generic$).*"][:properties][:printed_circuits_fabrication_data][:properties].has_key? key.to_sym
                capabilityschema[:properties][:open_trade_transfer_package][:properties][:products][:patternProperties][:"^(?!generic$).*"][:properties][:printed_circuits_fabrication_data][:properties][:stackup][:properties][:specified][:properties][key.to_sym] = {:type => "object", :properties => {} } unless capabilityschema[:properties][:open_trade_transfer_package][:properties][:products][:patternProperties][:"^(?!generic$).*"][:properties][:printed_circuits_fabrication_data][:properties][:stackup][:properties][:specified][:properties].has_key? key.to_sym
                if subvalue.is_a? String
                  if subvalue.match("^(\\d*|\\d*.\\d*)\\.\\.\\.(\\d*|\\d*.\\d*)$") #This is a value range
                    from, too = subvalue.match("^(\\d*|\\d*.\\d*)\\.\\.\\.(\\d*|\\d*.\\d*)$").captures
                    newhash = eval("{:minimum => #{from}, :maximum => #{too}}")
                    capabilityschema[:properties][:open_trade_transfer_package][:properties][:products][:patternProperties][:"^(?!generic$).*"][:properties][:printed_circuits_fabrication_data][:properties][key.to_sym][:properties][subkey.to_sym] = newhash
                    capabilityschema[:properties][:open_trade_transfer_package][:properties][:products][:patternProperties][:"^(?!generic$).*"][:properties][:printed_circuits_fabrication_data][:properties][:stackup][:properties][:specified][:properties][key.to_sym][:properties][subkey.to_sym] = newhash
                  else # This is a normal string - check for commas
                    enum = []
                    subvalue.split(',').each { |enumvalue| enum << enumvalue.strip }
                    capabilityschema[:properties][:open_trade_transfer_package][:properties][:products][:patternProperties][:"^(?!generic$).*"][:properties][:printed_circuits_fabrication_data][:properties][key.to_sym][:properties][subkey.to_sym] = eval("{:enum => #{enum}}")
                    capabilityschema[:properties][:open_trade_transfer_package][:properties][:products][:patternProperties][:"^(?!generic$).*"][:properties][:printed_circuits_fabrication_data][:properties][:stackup][:properties][:specified][:properties][key.to_sym][:properties][subkey.to_sym] = eval("{:enum => #{enum}}")
                  end
                elsif subvalue.is_a? Numeric # This is a normal string
                  capabilityschema[:properties][:open_trade_transfer_package][:properties][:products][:patternProperties][:"^(?!generic$).*"][:properties][:printed_circuits_fabrication_data][:properties][key.to_sym][:properties][subkey.to_sym] = eval("{:enum => [#{subvalue.to_s}]}")
                  capabilityschema[:properties][:open_trade_transfer_package][:properties][:products][:patternProperties][:"^(?!generic$).*"][:properties][:printed_circuits_fabrication_data][:properties][:stackup][:properties][:specified][:properties][key.to_sym][:properties][subkey.to_sym] = eval("{:enum => [#{subvalue.to_s}]}")
                end
              end
            end
          end
          begin
            capabilitiesvalidate = JSON::Validator.fully_validate(capabilityschema.to_json, json_productfile, :errors_as_objects => true)
          rescue JSON::Schema::ReadFailed
            $errors = true
            returnarray[:error] = true
            returnarray[:errormessage] = "Could not read the schema #{$jsonschema_v1}"
          rescue JSON::Schema::SchemaError
            $errors = true
            returnarray[:error] = true
            returnarray[:errormessage] = "Something was wrong with the schema #{$jsonschema_v1}"
          end
          unless $errors
            if capabilitiesvalidate.count > 0
              returnarray[:error] = true
              returnarray[:errormessage] = "The product to check did not meet the requirements"
              capabilitiesvalidate.each do |valerror|
                returnarray[:capabilitieserrors][valerror[:fragment]] = [] unless returnarray[:capabilitieserrors].has_key? valerror[:fragment]
                begin
                  scrap, keep, scrap2 = valerror[:message].match("^(The\\sproperty\\s\\'[\\s\\S]*\\'\\s)([\\s\\S]*)(\\sin\\sschema[\\s\\S]*)$").captures
                rescue
                  keep = valerror[:message]
                end
                returnarray[:capabilitieserrors][valerror[:fragment]] << keep
              end
            end
          end
        end
      end
    end

    return returnarray

  end
end
