require 'json'
class Circuitdata::Tools
  def initialize(schema, definitions)
    @schema = schema
    @definitions = definitions
    @ra = {}
  end

  def update_ra(type, key, value)
    if key == :materials
      update_ra(type, :dielectric, value[:properties][:printed_circuits_fabrication_data][:properties][:dielectrics])
      update_ra(type, :soldermask, value[:properties][:printed_circuits_fabrication_data][:properties][:soldermasks])
      update_ra(type, :stiffener, value[:properties][:printed_circuits_fabrication_data][:properties][:stiffeners])
      return
    end
    parsed_elements = @definitions
    unless @ra[:structured][:elements].has_key? key
      @ra[:structured][:elements][key] = {
        :type => value[:type],
        :elements => {},
        :name => nil,
        :description => nil,
        :aliases => nil
      }
      @ra[:structured][:elements][key][:name] = value[:descriptive_name] if value.has_key? :descriptive_name
      @ra[:structured][:elements][key][:description] = value[:description] if value.has_key? :description
      if value.has_key? :aliases
        @ra[:structured][:elements][key][:aliases] = value[:aliases] unless value[:aliases] == ""
      end
    end
    if value[:type] == "array"
      subelement = value[:items]
    else
      subelement = value
    end
    if subelement.has_key? :properties
      subelement[:properties].each do |skey, svalue|
        unless @ra[:structured][:elements][key][:elements].has_key? skey
          @ra[:structured][:elements][key][:elements][skey] = {
            :in_product_generic => false,
            :in_product_stackup => false,
            :in_profile_default => false,
            :in_profile_enforced => false,
            :in_profile_restricted => false,
            :in_custom => false,
            :in_capabilities => false,
            :type => nil,
            :arrayitems => nil,
            :enum => nil,
            :enum_description => nil,
            :description => nil,
            :uom => nil,
            :minimum => nil,
            :maximum => nil
          }
          if svalue.has_key? :$ref
            elements = svalue[:$ref].split('/')
            if elements.length == 4
              element = parsed_elements[elements[1].to_sym][elements[2].to_sym][elements[3].to_sym]
            elsif elements.length == 5
              element = parsed_elements[elements[1].to_sym][elements[2].to_sym][elements[3].to_sym][elements[4].to_sym]
            else
              element = parsed_elements[elements[1].to_sym][elements[2].to_sym][elements[3].to_sym][elements[4].to_sym][elements[5].to_sym]
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
              @ra[:structured][:elements][key][:elements][skey][:type] = element[:type]
              if element[:type] == "array"
                if element.has_key? :items and element[:items].has_key? :type
                  @ra[:structured][:elements][key][:elements][skey][:arrayitems] == element[:items][:type]
                end
              end
            end
            if element.has_key? :enum
              @ra[:structured][:elements][key][:elements][skey][:enum] = element[:enum]
              @ra[:structured][:elements][key][:elements][skey][:enum_description] = element[:enum_description] if element.has_key? :enum_description
            end
            @ra[:structured][:elements][key][:elements][skey][:description] = element[:description] if element.has_key? :description
            @ra[:structured][:elements][key][:elements][skey][:uom] = element[:uom] if element.has_key? :uom
            @ra[:structured][:elements][key][:elements][skey][:minimum] = element[:minimum] if element.has_key? :minimum
            @ra[:structured][:elements][key][:elements][skey][:maximum] = element[:maximum] if element.has_key? :maximum
          end
        else
          if [:in_profile_restricted, :in_capabilities].include? type
            if @ra[:structured][:elements][key][:elements][skey][:type].nil?
              @ra[:structured][:elements][key][:elements][skey][:type] = svalue[:type] unless ['array', 'object'].include? svalue[:type]
            end
            case @ra[:structured][:elements][key][:elements][skey][:type]
            when *["number", "integer", "boolean", "string"]
              @ra[:structured][:elements][key][:elements][skey][:type] = "number" if @ra[:structured][:elements][key][:elements][skey][:type] == "integer"
              unless ( svalue.has_key? :type and svalue[:type] == "array" ) and ( svalue.has_key? :items and svalue[:items].has_key? :type and svalue[:items][:type] == @ra[:structured][:elements][key][:elements][skey][:type])
                (@ra[:errors][type][key] ||= {})[skey] = "Type is #{@ra[:structured][:elements][key][:elements][skey][:type]}, wrong check"
              end
              if type == :in_profile_restricted and not @ra[:structured][:elements][key][:elements][skey][:enum].nil? and svalue.has_key? :minItems
                puts
                (@ra[:errors][type][key] ||= {})[skey] = "Error in profile restricted where enum is not considered"
              end
            when "array"
              unless svalue.has_key? :type and svalue[:type] == "array"
                (@ra[:errors][type][key] ||= {})[skey] = "Type is #{@ra[:structured][:elements][key][:elements][skey][:type]}, wrong check"
              end
            else
              (@ra[:errors][type][key] ||= {})[skey] = "Unknown type #{@ra[:structured][:elements][key][:elements][skey][:type]} in #{key}, #{skey} when doing #{type}"
            end
          end
        end
        @ra[:structured][:elements][key][:elements][skey][type] = true
      end
    end
  end

  def create_structure
    @ra[:structured] = {:elements => {}, :custom => {}}
    @ra[:errors] = {:in_profile_restricted => {}, :in_capabilities => {}}
    parsed_schema = @schema
    # Go through all products
    parsed_schema[:properties][:open_trade_transfer_package][:properties][:products][:patternProperties]["^(?!generic$).*".to_sym][:properties][:printed_circuits_fabrication_data][:properties].each do |key, value|
      self.update_ra(:in_product_generic, key, value)
    end
    # Go through all profiles
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
    # Go through all capabilities
    parsed_schema[:properties][:open_trade_transfer_package][:properties][:capabilities][:properties][:printed_circuits_fabrication_data][:properties].each do |key, value|
      self.update_ra(:in_capabilities, key, value)
    end
    # Go through all custom
    parsed_schema[:properties][:open_trade_transfer_package][:properties][:custom][:properties].each do |key, value|
      self.update_ra(:in_custom, key, value)
    end

    @ra[:structured][:elements].sort.to_h
    @ra[:structured][:elements].delete(:version)
    @ra[:structured][:elements][:stackup].delete(:specified)
    return @ra
  end

  def create_documentation(ra)
    ra[:documentation] = "## Elements and tags\n"
    ra[:structured][:elements].each do |element_key, element_value|
      ra[:documentation] += "### #{element_key} [link](##{element_key.to_s.downcase.tr(" ", "-")})\n"
      element_value[:elements].each do |e_key, e_value|
        ra[:documentation] += "* #{e_key}\n"
      end
      ra[:documentation] += "\n"
    end
    ra[:structured][:elements].each do |element_key, element_value|
      ra[:documentation] += "### #{element_key}\n"
      ra[:documentation] += "Name: #{element_value[:descriptive_name]}\n\n" unless element_value[:descriptive_name].nil?
      ra[:documentation] += "Aliases: #{element_value[:aliases]}\n\n" unless element_value[:aliases].nil?
      ra[:documentation] += "#{element_value[:description]}\n" unless element_value[:description].nil?
      ra[:documentation] += "\n"
      if element_value[:type] == "array"
        ra[:documentation] += "**You must specify this as en array when used in a generic product description or a stackup, but as a object when used in any of the other parts. Read more [here](#elements-that-are-both-arrays-and-objects)**\n\n"
      end
      element_value[:elements].each do |e_key, e_value|
        ra[:documentation] += "#### #{e_key}\n"
        ra[:documentation] += "Aliases: #{e_value[:aliases]}\n\n" unless e_value[:aliases].nil?
        ra[:documentation] += "#{e_value[:description]}\n\n" unless e_value[:description].nil?
        ra[:documentation] += "Unit of Measure: #{e_value[:uom][0]}\n\n" unless e_value[:uom].nil?
        if e_value.has_key? :enum and not e_value[:enum].nil?
          ra[:documentation] += "Use one of these values:\n"
          e_value[:enum].each do |ev|
            ra[:documentation] += "* #{ev}"
            if e_value.has_key? :enum_description and not e_value[:enum_description].nil? and e_value[:enum_description].has_key? ev.to_sym and not e_value[:enum_description][ev.to_sym].nil?
              ra[:documentation] += " (#{e_value[:enum_description][ev.to_sym]})\n"
            else
              ra[:documentation] += "\n"
            end
          end
          ra[:documentation] += "\n"
        end
        ra[:documentation] += "|  | Generic product | Stackup | Profile defaults | Profile enforced | Profile restricted | Capabilities | Custom |\n"
        ra[:documentation] += "|-:|:---------------:|:-------:|:----------------:|:----------------:|:------------------:|:------------:|:------:|\n| **Use in:** | "
        [:in_product_generic, :in_product_stackup, :in_profile_default, :in_profile_enforced, :in_profile_restricted, :in_capabilities, :in_custom].each do |part|
          e_value[part] ? ra[:documentation] += "Allowed | " : ra[:documentation] += "Disallowed | "
        end
        ra[:documentation] += "\n|**Format:** | #{e_value[:type]} | #{e_value[:type]} | #{e_value[:type]} | #{e_value[:type]} | Array of #{e_value[:type]}s | Array of #{e_value[:type]}s | Array of #{e_value[:type]}s |\n"
        if e_value[:enum].nil? and e_value[:type] == "number"
          ra[:documentation] += "|**Min value:** | #{e_value[:minimum]} | #{e_value[:minimum]} | #{e_value[:minimum]} | #{e_value[:minimum]} | Each item: #{e_value[:minimum]} | Each item: #{e_value[:minimum]} | Each item: #{e_value[:minimum]} |\n" unless e_value[:minimum].nil?
          ra[:documentation] += "|**Max value:** | #{e_value[:maximum]} | #{e_value[:maximum]} | #{e_value[:maximum]} | #{e_value[:maximum]} | Each item  : #{e_value[:maximum]} | Each item: #{e_value[:maximum]} | Each item: #{e_value[:maximum]} |\n" unless e_value[:maximum].nil?
        end
        ra[:documentation] += "\n"
      end
    end
    return ra[:documentation]
  end

end
