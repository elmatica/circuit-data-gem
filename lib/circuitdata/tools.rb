class Circuitdata::Tools
  def initialize()
    require 'json'
    @schema_path = File.join(File.dirname(__FILE__), 'schema_files/v1/ottp_circuitdata_schema.json')
    @definitions_path = File.join(File.dirname(__FILE__), 'schema_files/v1/ottp_circuitdata_schema_definitions.json')
    @ra = {}
  end

  def update_ra(type, key, value)
    parsed_elements = Circuitdata.read_json(@definitions_path)[2]
    unless @ra[:structured].has_key? key
      @ra[:structured][key] = {
        :type => value[:type],
        :elements => {},
        :name => nil,
        :description => nil,
        :aliases => nil
      }
      @ra[:structured][key][:name] = value[:name] if value.has_key? :name
      @ra[:structured][key][:description] = value[:decription] if value.has_key? :decription
      if value.has_key? :aliases
        @ra[:structured][key][:aliases] = value[:aliases] unless value[:aliases] == ""
      end
    end
    if value.has_key? :properties
      value[:properties].each do |skey, svalue|
        unless @ra[:structured][key][:elements].has_key? skey
          @ra[:structured][key][:elements][skey] = {
            :in_product_generic => false,
            :in_product_stackup => false,
            :in_profile_default => false,
            :in_profile_enforced => false,
            :in_profile_restricted => false,
            :in_capabilities => false,
            :type => nil,
            :arrayitems => nil,
            :enum => nil,
            :description => nil,
            :uom => nil,
            :minimum => nil,
            :maximum => nil,
            :in_profile_restricted_regex => nil,
            :in_capabilities_regex => nil
          }
          if svalue.has_key? :$ref
            elements = svalue[:$ref].split('/')
            if elements.length < 5
              element = parsed_elements[elements[1].to_sym][elements[2].to_sym][elements[3].to_sym]
            else
              element = parsed_elements[elements[1].to_sym][elements[2].to_sym][elements[3].to_sym][elements[4].to_sym]
            end
          else
            element = nil
            [:rigid_conductive_layer, :flexible_conductive_layer].include? key.to_sym ? newkey = :conductive_layer : newkey = key.to_sym
            if parsed_elements[:definitions][:elements].has_key? newkey
              element = parsed_elements[:definitions][:elements][newkey][skey.to_sym] if parsed_elements[:definitions][:elements][newkey].has_key? skey.to_sym
            end
          end
          unless element.nil?
            if element.has_key? :type
              @ra[:structured][key][:elements][skey][:type] = element[:type]
              if element[:type] == "array"
                if element.has_key? :items and element[:items].has_key? :type
                  @ra[:structured][key][:elements][skey][:arrayitems] == element[:items][:type]
                end
              end
            end
            @ra[:structured][key][:elements][skey][:enum] = element[:enum] if element.has_key? :enum
            @ra[:structured][key][:elements][skey][:description] = element[:description] if element.has_key? :description
            @ra[:structured][key][:elements][skey][:uom] = element[:uom] if element.has_key? :uom
            @ra[:structured][key][:elements][skey][:minimum] = element[:minimum] if element.has_key? :minimum
            @ra[:structured][key][:elements][skey][:maximum] = element[:maximum] if element.has_key? :maximum
          end
        else
          if [:in_profile_restricted, :in_capabilities].include? type
            case @ra[:structured][key][:elements][skey][:type]
            when *["number", "integer", "boolean", "string"]
              @ra[:structured][key][:elements][skey][:type] = "number" if @ra[:structured][key][:elements][skey][:type] == "integer"
              unless ( svalue.has_key? :type and svalue[:type] == "array" ) and ( svalue.has_key? :items and svalue[:items].has_key? :type and svalue[:items][:type] == @ra[:structured][key][:elements][skey][:type])
                (@ra[:errors][type][key] ||= {})[skey] = "Type is #{@ra[:structured][key][:elements][skey][:type]}, wrong check"
              end
            when "array"
              unless svalue.has_key? :type and svalue[:type] == "array"
                (@ra[:errors][type][key] ||= {})[skey] = "Type is #{@ra[:structured][key][:elements][skey][:type]}, wrong check"
              end
            else
              puts "unknown type #{@ra[:structured][key][:elements][skey][:type]} in #{key}, #{skey}"
            end
          end
        end
        @ra[:structured][key][:elements][skey][type] = true
      end
    end
  end

  def create_structure
    @ra[:structured] = {}
    @ra[:errors] = {:in_profile_restricted => {}, :in_capabilities => {}}
    parsed_schema = Circuitdata.read_json(@schema_path)[2]
    parsed_schema[:properties][:open_trade_transfer_package][:properties][:products][:patternProperties]["^(?!generic$).*".to_sym][:properties][:printed_circuits_fabrication_data][:properties].each do |key, value|
      self.update_ra(:in_product_generic, key, value)
    end
    ["defaults", "restricted", "enforced"].each do |sym|
      parsed_schema[:properties][:open_trade_transfer_package][:properties][:profiles][:properties][sym.to_sym][:properties][:printed_circuits_fabrication_data][:properties].each do |key, value|
        case sym
        when "defaults"
          t = :in_profile_default
        when "restricted"
          t = :in_profile_restricted
        when "enforced"
          t = :in_profile_enforced
        end
        self.update_ra(t, key, value)
      end
    end
    parsed_schema[:properties][:open_trade_transfer_package][:properties][:capabilities][:properties][:printed_circuits_fabrication_data][:properties].each do |key, value|
      self.update_ra(:in_capabilities, key, value)
    end
    @ra[:structured].sort.to_h
    @ra[:structured].delete(:version)
    return @ra
  end

  def create_documentation(ra)
    ra[:documentation] = "## Elements and tags\n"
    ra[:structured].each do |element_key, element_value|
      ra[:documentation] += "[#{element_key}](##{element_key.to_s.downcase.tr(" ", "-")})\n"
      element_value[:elements].each do |e_key, e_value|
        ra[:documentation] += "* #{e_key}\n"
      end
      ra[:documentation] += "\n"
    end
    ra[:structured].each do |element_key, element_value|
      ra[:documentation] += "### #{element_key}\n"
      ra[:documentation] += "Name: #{element_value[:name]}\n" unless element_value[:name].nil?
      ra[:documentation] += "Aliases: #{element_value[:aliases]}\n" unless element_value[:aliases].nil?
      ra[:documentation] += "#{element_value[:description]}\n" unless element_value[:description].nil?
      ra[:documentation] += "\n"
      element_value[:elements].each do |e_key, e_value|
        ra[:documentation] += "#### #{e_key}\n"
        ra[:documentation] += "Aliases: #{e_value[:aliases]}\n" unless e_value[:aliases].nil?
        ra[:documentation] += "#{e_value[:description]}\n" unless e_value[:description].nil?
        ra[:documentation] += "Unit of Measure: #{e_value[:uom][0]}\n" unless e_value[:uom].nil?
        unless e_value[:type].nil?
          if e_value[:type] == "array"
            if e_value[:arrayitems].nil?
              ra[:documentation] += "Type: #{e_value[:type].capitalize} of unknown type\n"
            else
              ra[:documentation] += "Type: #{e_value[:type].capitalize} of #{e_value[:arrayitems].capitalize}\n"
            end
          else
            ra[:documentation] += "Type: #{e_value[:type].capitalize}\n"
          end
        end
        if e_value.has_key? :enum and not e_value[:enum].nil?
          ra[:documentation] += "Use one of these values:\n"
          e_value[:enum].each do |ev|
            ra[:documentation] += "* #{ev}\n"
          end
        end
        ra[:documentation] += "Use in:\n"
        e_value[:in_product_generic] ? ra[:documentation] += "* *Generic product section: Allowed*\n" :  ra[:documentation] += "* *Generic product section: Disallowed*\n"
        e_value[:in_product_stackup] ? ra[:documentation] += "* *Stackup product section: Allowed*\n" :  ra[:documentation] += "* *Gtackup product section: Disallowed*\n"
        e_value[:in_profile_default] ? ra[:documentation] += "* *Profile defaults section: Allowed*\n" :  ra[:documentation] += "* *Profile defaults section: Disallowed*\n"
        e_value[:in_profile_enforced] ? ra[:documentation] += "* *Profile enforced section: Allowed*\n" :  ra[:documentation] += "* *Profile enforced section: Disallowed*\n"
        e_value[:in_profile_restricted] ? ra[:documentation] += "* *Profile restricted section: Allowed*\n" :  ra[:documentation] += "* *Profile restricted section: Disallowed*\n"
        ra[:documentation] += "*  - Value in restricted section must match regex #{e_value[:in_profile_restricted_regex]}\n" unless e_value[:in_profile_restricted_regex].nil?
        e_value[:in_capabilities] ? ra[:documentation] += "* *Capabilites section: Allowed*\n" :  ra[:documentation] += "* *Capabilities section: Disallowed*\n"
        ra[:documentation] += "*  - Value in capabilites section must match regex #{e_value[:in_capabilities_regex]}\n" unless e_value[:in_capabilities_regex].nil?
        ra[:documentation] += "\n"
      end
    end
    puts ra[:documentation]
  end

end
