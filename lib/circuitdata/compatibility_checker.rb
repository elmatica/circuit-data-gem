class Circuitdata::CompatibilityChecker
  SCHEMA_FILE_PATH = File.join(__dir__, 'schema_files/v1/ottp_circuitdata_skeleton_schema.json')

  def initialize(product_file, check_file, docu, schema_path = SCHEMA_FILE_PATH)
    require 'json'
    require 'json-schema'

    @product_file = product_file
    @check_file = check_file
    @schema_path = schema_path
    @docu = docu
    # Final hash
    @fh = {error: false, message: nil, errors: {validation: {}, restricted: {}, enforced: {}, capabilities: {}}}
  end

  def start_check
    # Initialize & validate
    @fh[:error], @fh[:message], product_data = Circuitdata.read_json(@product_file)
    return @fh if @fh[:error]
    @fh[:error], @fh[:message], @fh[:errors][:validation] = Circuitdata.validate(product_data)
    return @fh if @fh[:error]
    if @check_file.present?
      @fh[:error], @fh[:message], check_data = Circuitdata.read_json(@check_file)
      return @fh if @fh[:error]
      @fh[:error], @fh[:message], @fh[:errors][:validation] = Circuitdata.validate(check_data)
      return @fh if @fh[:error]
      f2_types = Circuitdata.get_data_summary(check_data)[1]

      # read the schema
      schema = JSON.parse(File.read(@schema_path), symbolize_names: true)
      deref_schema = Circuitdata::Dereferencer.dereference(schema, File.dirname(@schema_path))
      restricted_schema = enforced_schema = capability_schema = deref_schema
      # Compare the content
      perform_comparison(product_data, check_data, restricted_schema, 'restricted') if f2_types.include? 'profile_restricted'
      perform_comparison(product_data, check_data, enforced_schema, 'enforced') if f2_types.include? 'profile_enforced'
      perform_comparison(product_data, check_data, capability_schema, 'capabilities') if f2_types.include? 'capabilities'
    end

    @fh
  end

  def perform_comparison(product_data, check_data, schema, type)
    ra = @docu.create_structure

    case type
      when 'restricted'
        check_hash = check_data.dig(:open_trade_transfer_package, :profiles, :restricted, :printed_circuits_fabrication_data)
      when 'enforced'
        check_hash = check_data.dig(:open_trade_transfer_package, :profiles, :enforced, :printed_circuits_fabrication_data)
      when 'capabilities'
        check_hash = check_data.dig(:open_trade_transfer_package, :capabilities, :printed_circuits_fabrication_data)
      else
        check_hash = {}
    end

    common_hash = schema.dig(:properties, :open_trade_transfer_package, :properties, :products, :patternProperties, :'^(?!generic$).*', :properties, :printed_circuits_fabrication_data, :properties)
    check_hash.each do |k, v|
      v.each do |kl1, vl1| # level 1
        unless [:dielectric, :soldermask, :stiffener].include? k.to_sym
          common_hash[k.to_sym]||= {:type => 'object', :properties => {}}
          #common_hash[:stackup][:properties][:specified][:properties][k.to_sym] ||= {:type => 'object', :properties => {}}
        end
        enum = []
        required = []
        case type
          when 'restricted'
            case vl1[0].class.name
            when 'String'
              vl1.each {|enumvalue| enum << enumvalue.strip}
              new_hash = {:not => {:anyOf => [{ :enum => enum }]}}
            when 'Boolean', 'FalseClass', 'TrueClass'
              vl1.each do |enumvalue|
                required << kl1.to_s if enumvalue == false
                enum << enumvalue
              end
              new_hash = {:not => {:anyOf => [{ :enum => enum }]}}
            when 'Numeric', 'Float'
              if ra.dig(:structured, :elements, k.to_sym, :elements, kl1.to_sym, :enum).nil?
                new_hash = {:anyOf => [{ :minimum => vl1[0], :maximum => vl1[1] }]}
              else
                vl1.each {|enumvalue| enum << enumvalue}
                new_hash = {:not => {:anyOf => [{ :enum => enum }]}}
              end
            end
          when 'enforced'
            enum << vl1
            new_hash = eval("{:enum => #{enum}}")
          when 'capabilities'
            case vl1[0].class.name
            when 'String'
              vl1.each {|enumvalue| enum << enumvalue.strip}
              new_hash = {:anyOf => [{ :enum => enum }]}
            when 'Boolean', 'FalseClass', 'TrueClass'
              vl1.each do |enumvalue|
                required << kl1.to_s if enumvalue == true
                enum << enumvalue
              end
              new_hash = {:anyOf => [{ :enum => enum }]}
            when 'Numeric'
              vl1.each {|enumvalue| enum << enumvalue.strip}
              new_hash = {:anyOf => [{ :minimum => vl1[0], :maximum => vl1[1] }]}
            when 'Integer', 'Float'
              if vl1.length == 1
                new_hash = {:anyOf => [{ :minimum => vl1[0], :maximum => vl1[0] }]}
              elsif vl1.length == 2
                new_hash = {:anyOf => [{ :minimum => vl1[0], :maximum => vl1[1] }]}
              else
                fail StandardError, "Unhandled array length=#{vl1.length} key=#{kl1}"
              end
            else
              fail StandardError, "Unhandled type=#{vl1[1].class.name} key=#{kl1}"
            end
        end
        case k.to_sym
        when :dielectric
          schema[:properties][:open_trade_transfer_package][:properties][:custom][:properties][:materials][:properties][:printed_circuits_fabrication_data][:properties][:dielectrics][:items][:properties][kl1.to_sym] = new_hash
          schema[:properties][:open_trade_transfer_package][:properties][:custom][:properties][:materials][:properties][:printed_circuits_fabrication_data][:properties][:dielectrics][:items][:required] = required
        when :soldermask
          schema[:properties][:open_trade_transfer_package][:properties][:custom][:properties][:materials][:properties][:printed_circuits_fabrication_data][:properties][:soldermasks][:items][:properties][kl1.to_sym] = new_hash
          schema[:properties][:open_trade_transfer_package][:properties][:custom][:properties][:materials][:properties][:printed_circuits_fabrication_data][:properties][:soldermasks][:items][:required] = required
        when :stiffener
          schema[:properties][:open_trade_transfer_package][:properties][:custom][:properties][:materials][:properties][:printed_circuits_fabrication_data][:properties][:stiffeners][:items][:properties][kl1.to_sym] = new_hash
          schema[:properties][:open_trade_transfer_package][:properties][:custom][:properties][:materials][:properties][:printed_circuits_fabrication_data][:properties][:stiffeners][:items][:required] = required
        else
          common_hash[k.to_sym][:properties][kl1.to_sym] = new_hash
          common_hash[k.to_sym][:required] = required
        end
        #common_hash[:stackup][:properties][:specified][:properties][k.to_sym][:properties][kl1.to_sym] = new_hash
        #common_hash[:stackup][:properties][:specified][:properties][k.to_sym][:properties][kl1.to_sym] = new_hash
      end if v.is_a? Hash

      common_hash[k.to_sym][:additionalProperties] = false if (v.is_a?(Hash) && type == 'capabilities')
    end
    # perform validations
    begin
      validation_errors = JSON::Validator.fully_validate(schema.to_json, product_data, :errors_as_objects => true)

      if validation_errors.any?
        @fh[:error] = true
        @fh[:message] = 'The product to check did not meet the requirements'

        validation_errors.each do |error|
          error_array = []
          begin
            error_array << error[:message].match("^(The\\sproperty\\s\\'[\\s\\S]*\\'\\s)([\\s\\S]*)(\\sin\\sschema[\\s\\S]*)$").captures[1]
          rescue
            error_array << error[:message]
          end
          @fh[:errors][type.to_sym][error[:fragment]] = error_array
        end
      end
    rescue JSON::Schema::ReadFailed
      @fh[:error] = true
      @fh[:message] = "Could not read the submitted `#{type}` schema" # enforced_schema
    rescue JSON::Schema::SchemaError
      @fh[:error] = true
      @fh[:message] = "Something was wrong with the submitted `#{type}` schema" # enforced_schema
    end
  end
end
