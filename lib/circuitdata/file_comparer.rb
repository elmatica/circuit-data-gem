class Circuitdata::FileComparer
  def initialize(file_hash, validate_origins)
    @file_hash = file_hash
    @validate_origins = validate_origins
    @rows = {}
    @nh = {} # a new_hash to combine all the data
    @columns = []
    @default_column = nil
    @master_column = nil
    # Final hash
    @fh = {error: false, message: nil, conflict: false, product_name: nil, columns: nil, master_column: nil, rows: nil}
  end

  def compare
    # Initial check
    unless @file_hash.is_a? Hash
      @fh[:error] = true
      @fh[:message] = 'You have to feed this function with a hash of names and hashes'
      return @fh
    end

    # Process the hashes
    products_array = []
    @file_hash.each do |k, v|
      # read content
      @fh[:error], @fh[:message], file_content = Circuitdata.read_json(v)
      return @fh if @fh[:error]
      products, types = Circuitdata.get_data_summary(file_content)
      products_array.push(*products) # add products to tracking array
      # populate the new_hash to be used later
      @nh[k] = {types: types, products: products, data: file_content}
    end

    # check if the files content meet the requirements
    if valid_product?(products_array)
      @fh[:product_name] = products_array.first.to_s
      @columns = @nh.keys
      # get all data with products in it
      product_hashes = @nh.select{|k, v| v[:products].any?}
      product_columns = product_hashes.keys

      # Add conflicts into the new_hash
      product_hashes.each do |column_k, column_v|
        master_json = column_v.dig(:data)
        @nh.each do |file_k, file_v|
          products, data = file_v[:products], file_v[:data]
          check_results = Circuitdata.compatibility_checker(master_json, data, false)
          # format the conflicts correctly here
          file_v[:conflicts] ||= {}
          file_v[:conflicts][column_k] = get_validation_summary(check_results, file_k)
          # initialize the rows format - for all the product items
          product_hash = data.dig(:open_trade_transfer_package, :products, @fh[:product_name].to_sym, :printed_circuits_fabrication_data)
          if products.any?
            init_row_format(product_hash)
          end
        end
        # Initialize the rows format - for all default profile items
        @default_column, file_v = @nh.select{|k, v| v[:types].include?("profile_defaults")}.first # this should only be a single file
        data = file_v[:data]
        product_hash = data.dig(:open_trade_transfer_package, :profiles, :defaults, :printed_circuits_fabrication_data)
        init_row_format(product_hash)
      end

      # populate the @rows
      product_columns.each do |column|
        @master_column = column
        process_row_hash('populate')
      end
      # populate the @rows summary
      product_columns.each do |column|
        @master_column = column
        process_row_hash('get_summary')
      end
      process_row_hash('populate_defaults')
    end

    @fh[:columns] = @columns.unshift(:summary)
    @fh[:rows] = @rows
    @fh
  end

  def init_row_format(product_hash)
    product_hash.each do |k, v|
      if v.is_a?(Hash)
        @rows[k] ||= {}
        v.each do |kl1, vl1|
          @rows[k][kl1] ||= get_l1_hash(@columns)
        end
      else
        @rows[k] ||= []
        # if array functionality eg Holes
      end if ['Hash', 'Array'].include?(v.class.name)
    end
  end

  def process_row_hash(action)
    @rows.each do |k, v| # product elements level
      if v.is_a?(Hash)
        v.each do |kl1, vl1| # specification level
          value, conflict, conflicts_with, conflict_message = [], false, [], []
          vl1.each do |kl2, vl2| # the specification column level - call the function from here
            conflicts = @nh.dig(kl2, :conflicts, @master_column)
            case action
              when 'populate'
                check = conflicts.any? && conflicts.dig(:rows, k, kl1).present?
                vl2[:value] = @nh.dig(kl2, :data, :open_trade_transfer_package, :products, @fh[:product_name].to_sym, :printed_circuits_fabrication_data, k, kl1)
                vl2[:conflict] = check unless vl2[:conflict] # update only when the status is false
                vl2[:conflicts_with] = check ? vl2[:conflicts_with] << @master_column : []
                vl2[:conflict_message] = check ? vl2[:conflict_message] + conflicts&.dig(:rows, k, kl1) : []

                # update master_column conflicts with
                if check
                  master_row = @rows.dig(k, kl1, @master_column)
                  master_row[:conflicts_with] = master_row[:conflicts_with] + conflicts.dig(:master_conflicts)
                  master_row[:conflict] = true
                  master_row[:conflict_message] = (master_row[:conflict_message] + vl2[:conflict_message]).uniq
                end
              when 'get_summary'
                # get the summary items
                if kl2 != :summary
                  items_v = vl2[:value]
                  master_value = vl1.dig(@master_column, :value)
                  # dont test if the @master_column value is also nil
                  if value.empty? || !value.include?(items_v)
                    value << items_v
                    conflicts_with << kl2
                    # jump the default column
                    if kl2 != @master_column # Add errors to the specific rows items
                      # get the item type
                      col_type = get_column_type(@nh.dig(kl2, :types))
                      vl2[:conflict] = true
                      vl2[:conflicts_with] = (vl2[:conflicts_with] << @master_column).uniq
                      vl2[:conflict_message] = (vl2[:conflict_message] << customize_conflict_message(col_type, kl2, @master_column)).uniq
                      # update the master row
                      master_row = @rows.dig(k, kl1, @master_column)
                      master_row[:conflicts_with] = master_row[:conflicts_with] << kl2
                      master_row[:conflict] = true
                      # get a customized error message here
                      master_row[:conflict_message] = (master_row[:conflict_message] << customize_conflict_message(col_type, @master_column, kl2)).uniq
                    end
                  end unless items_v.nil? || master_value.nil?
                  conflict = true if vl2[:conflict]
                  conflicts_with = conflicts_with + vl2[:conflicts_with]
                  conflict_message = conflict_message + vl2[:conflict_message]
                end
              when 'populate_defaults'
                if kl2 == @default_column
                  vl2[:value] = @nh.dig(kl2, :data, :open_trade_transfer_package, :profiles, :defaults, :printed_circuits_fabrication_data, k, kl1)
                  vl2[:conflict] = false
                  vl2[:conflicts_with] = []
                  vl2[:conflict_message] = []
                end
            end
          end
          case action
            when 'get_summary'
              if value.count > 1
                conflict = true
              else
                value = value.first
              end
              vl1[:summary] = {value: value, conflict: conflict, conflicts_with: conflicts_with.uniq, conflict_message: conflict_message.uniq}
            when 'populate_defaults'
              # if all the values are blank, use the default value
              vl1[:summary][:value] ||= vl1.dig(@default_column, :value)
          end
          if action == 'get_summary'
          end
          @fh[:conflict] = true if conflict
        end
      else
        # if array functionality eg Holes
      end
    end
  end

  def customize_conflict_message(type, col, conflicting_col)
    case type
      when :product
        "#{col.to_s} value conflicts with value from #{conflicting_col.to_s}"
      when :restricted
        "#{col.to_s} value is restricted in #{conflicting_col.to_s}"
      when :enforced
        "#{col.to_s} value conflicts with the enforced value from #{conflicting_col.to_s}"
      when :capability
        "#{col.to_s} value is outside the capabilities of #{conflicting_col.to_s}"
      else
        "There were some value conflicts"
    end
  end

  def get_column_type(types)
    types ||= []
    if types.include? "product"
      :product
    elsif types.include? "profile_restricted"
      :restricted
    elsif types.include? "profile_enforced"
      :enforced
    elsif types.include? "capabilities"
      :capability
    end
  end

  def get_validation_summary(validation, column)
    summary = {}
    if validation[:error]
      summary[:master_conflicts] ||= []
      summary[:master_conflicts] << column
      summary[:conflicts], summary[:rows] = true, {}
      validation[:errors].each do |type, errors| # validation, restricted, enforced, capabilities
        errors.each do |k, v|
          folders_stack = k.split('/')
          folder, spec = folders_stack[5], folders_stack[6]
          summary[:rows][folder.to_sym] ||= {}
          spec_message = summary[:rows][folder.to_sym][spec.to_sym] || []
          summary[:rows][folder.to_sym][spec.to_sym] = spec_message+v
        end if errors.any?
      end
    end
    summary
  end

  def get_l1_hash(columns)
    l1_hash = {}
    columns.each{|c| l1_hash[c]={} }
    l1_hash
  end

  def valid_product?(products_array)
    if products_array.uniq.count > 1
      @fh[:error] = true
      @fh[:message] = 'Your files contains several different product names'
      return false # validation fails because of different product names
    end
    if products_array.empty?
      @fh[:error] = true
      @fh[:message] = 'None of the files contains a product'
      return false # c=validation fails because there are no products
    end
    true
  end
end
