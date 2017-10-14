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
            :in_capabilities => false
          }
          if svalue.has_key? :$ref
            elements = svalue[:$ref].split('/')
            element = parsed_elements[elements[1].to_sym][elements[2].to_sym][elements[3].to_sym][elements[4].to_sym]
          else
            element = nil
            [:rigid_conductive_layer, :flexible_conductive_layer].include? key.to_sym ? newkey = :conductive_layer : newkey = key.to_sym
            if parsed_elements[:definitions][:elements].has_key? newkey
              element = parsed_elements[:definitions][:elements][newkey][skey.to_sym] if parsed_elements[:definitions][:elements][newkey].has_key? skey.to_sym
            end
          end
          unless element.nil?
            @ra[:structured][key][:elements][skey][:type] = element[:type] if element.has_key? :type
            @ra[:structured][key][:elements][skey][:enum] = element[:enum] if element.has_key? :enum
            @ra[:structured][key][:elements][skey][:description] = element[:description] if element.has_key? :description
            @ra[:structured][key][:elements][skey][:uom] = element[:uom] if element.has_key? :uom
          end
        end
        @ra[:structured][key][:elements][skey][type] = true
      end
    end
  end

  def create_structure
    @ra[:structured] = {}
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
      self.update_ra(:in_product_capabilities, key, value)
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
      element_value[:elements].each do |e_key, e_value|
        ra[:documentation] += "#### #{e_key}\n"
        ra[:documentation] += "Aliases: #{e_value[:aliases]}\n" unless e_value[:aliases].nil?
        ra[:documentation] += "#{e_value[:description]}\n" unless e_value[:description].nil?
        ra[:documentation] += "Unit of Measure: #{e_value[:uom][0]}\n" unless e_value[:uom].nil?
        e_value[:in_product_generic] ? ra[:documentation] += "*Use in generic product section: Allowed*\n" :  ra[:documentation] += "*Use in generic product section: Disallowed*\n"
        e_value[:in_product_stackup] ? ra[:documentation] += "*Use in stackup product section: Allowed*\n" :  ra[:documentation] += "*Use in stackup product section: Disallowed*\n"
        e_value[:in_profile_default] ? ra[:documentation] += "*Use in profile defaults section: Allowed*\n" :  ra[:documentation] += "*Use in profile defaults section: Disallowed*\n"
        e_value[:in_profile_enforced] ? ra[:documentation] += "*Use in profile enforced section: Allowed*\n" :  ra[:documentation] += "*Use in profile enforced section: Disallowed*\n"
        e_value[:in_profile_restricted] ? ra[:documentation] += "*Use in profile restricted section: Allowed*\n" :  ra[:documentation] += "*Use in profile restricted section: Disallowed*\n"
        e_value[:in_capabilities] ? ra[:documentation] += "*Use in capabilites section: Allowed*\n" :  ra[:documentation] += "*Use in capabilities section: Disallowed*\n"
        case e_value[:type]
        when "string"
          ra[:documentation] += "Type: String\n"
        when "integer"
          ra[:documentation] += "Type: Integer\n"
        when "number"
          ra[:documentation] += "Type: Number\n"
        end
        if e_value.has_key? :enum
          ra[:documentation] += "Use one of these values:\n"
          e_value[:enum].each do |ev|
            ra[:documentation] += "* #{ev}\n"
          end
        end
      end
    end
    puts ra[:documentation]
  end

end
