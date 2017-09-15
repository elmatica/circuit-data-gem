class Circuitdata::FileComparer
  def initialize(file_hash, validate_origins)
    @file_hash = file_hash
    @validate_origins = validate_origins
    @rows = {}
    @nh = {} # a new_hash to combine all the data
    @columns = []
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
      @fh[:master_column] ||= k # it'll be assigned for the first item
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
      # generate summary insert into rows for each array
      master_json = @nh.dig(@fh[:master_column], :data)
      @nh.each do |file_k, file_v|
        products, data = file_v[:products], file_v[:data]
        check_results = Circuitdata.compatibility_checker(master_json, data, false)
        file_v[:conflicts] = get_validation_summary(check_results, file_k)
        # initialize the rows format
        product_hash = data.dig(:open_trade_transfer_package, :products, @fh[:product_name].to_sym, :printed_circuits_fabrication_data)
        if products.any?
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
      end

      # populate the row hash
      process_row_hash('populate')
      process_row_hash('get_summary')
    end
    @fh[:columns] = @columns.unshift(:summary)
    @fh[:rows] = @rows
    @fh
  end

  def process_row_hash(action)
    @rows.each do |k, v| # product elements level
      if v.is_a?(Hash)
        v.each do |kl1, vl1| # specification level
          value, conflict, conflicts_with, conflict_message, value_cols = [], false, [], [], []
          vl1.each do |kl2, vl2| # the specification column level - call the function from here
            conflicts = @nh.dig(kl2, :conflicts)
            if action == 'populate'
              check = conflicts.any? && conflicts.dig(:rows, k, kl1).present?
              vl2[:value] = @nh.dig(kl2, :data, :open_trade_transfer_package, :products, @fh[:product_name].to_sym, :printed_circuits_fabrication_data, k, kl1)
              vl2[:conflict] = check
              vl2[:conflicts_with] = check ? [@fh[:master_column]] : []
              vl2[:conflict_message] = check ? conflicts.dig(:rows, k, kl1) : []
              # update master_column conflicts with
              if check
                master_row = @rows.dig(k, kl1, @fh[:master_column])
                master_row[:conflicts_with] = master_row[:conflicts_with] + conflicts.dig(:master_conflicts)
                master_row[:conflict] = true
                master_row[:conflict_message] = (master_row[:conflict_message] + vl2[:conflict_message]).uniq
              end
            else
              # get the summary items
              items_v = vl2[:value]
              if value.empty? || !value.include?(items_v)
                value << items_v
                conflicts_with << kl2
                value_cols << kl2 if kl2 != @fh[:master_column]
              end unless items_v.nil?
              conflict = true if vl2[:conflict]
              conflicts_with = conflicts_with + vl2[:conflicts_with]
              conflict_message = conflict_message + vl2[:conflict_message]
            end
          end
          if action == 'get_summary'
            if value.count > 1
              conflict_message.unshift("#{@fh[:master_column]} value conflicts with values from: #{value_cols.to_sentence}")
              conflict = true
            else
              value = value.first
            end
            vl1[:summary] = {value: value, conflict: conflict, conflicts_with: conflicts_with.uniq, conflict_message: conflict_message.uniq}
          end
          @fh[:conflict] = true if conflict
        end
      else
        # if array functionality eg Holes
      end
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
