class Circuitdata::FileComparer
  def initialize(file_hash, validate_origins)
    @file_hash = file_hash
    @validate_origins = validate_origins
    @rows = {}
    # Final hash
    @fh = {error: false, message: nil, product_name: nil, columns: nil, master_column: nil, rows: nil}
  end

  def compare
    # Initial check
    unless @file_hash.is_a? Hash
      @fh[:error] = true
      @fh[:message] = 'You have to feed this function with a hash of names and hashes'
      return @fh
    end

    nh = {} # a new_hash to combine all the data
    # Process the hashes
    products_array = []
    @file_hash.each do |k, v|
      @fh[:master_column] ||= k.to_s # it'll be assigned for the first item
      # read content
      @fh[:error], @fh[:message], file_content = Circuitdata.read_json(v)
      return @fh if @fh[:error]
      products, types = Circuitdata.get_data_summary(file_content)
      products_array.push(*products) # add products to tracking array
      # populate the new_hash to be used later
      nh[k] = {types: types, products: products, data: file_content}
    end

    # check if the files content meet the requirements
    if valid_product?(products_array)
      @fh[:product_name] = products_array.first.to_s
      columns = nh.keys.unshift(:summary)
      @fh[:columns] = columns
      # generate summary insert into rows for each array
      master_json = nh.dig(@fh[:master_column].to_sym, :data)
      nh.each do |file_k, file_v|
        types, products, data = file_v[:types], file_v[:products], file_v[:data]
        check_results = Circuitdata.compatibility_checker(master_json, data, false)

        # from the results, we will populate the rows
        if products.any?
          product_hash = data.dig(:open_trade_transfer_package, :products, @fh[:product_name].to_sym, :printed_circuits_fabrication_data)
          # build the hash
          product_hash.each do |k, v|
            if v.is_a?(Hash)
              @rows[k] ||= {}
              v.each do |kl1, vl1|
                @rows[k][kl1] ||= get_l1_hash(columns)
              end
            else
              @rows[k] ||= []
              # if array functionality eg Holes
            end if ['Hash', 'Array'].include?(v.class.name)
            @rows[k] ||= v.is_a?(Hash) ? {} : [] if ['Hash', 'Array'].include?(v.class.name)
          end
        end

        # process the results here - to be used for decision making below
        # processed_data = process_check_results(check_results, types)

        @rows.each do |k, v| # product elements level
          if v.is_a?(Hash)
            v.each do |kl1, vl1| # specification level
              vl1.each do |kl2, vl2| # the specification column level - call the function from here
                get_row_content(kl2, vl2, types, {}) # generate the row items here - pass all needed data for decisions
              end
            end
          else
            # if array functionality eg Holes
          end
        end
      end
    end
    @fh[:rows] = @rows
    @fh
  end

  def process_check_results(check_results, types)
    # values = {} # to hold the values to be returned
    # validation_error = check_results[:errors][:capabilities]
    types.each do |type|
      case type
        when 'profile_restricted'
          type_error = check_results[:errors][:restricted]
        when 'profile_enforced'
          type_error = check_results[:errors][:enforced]
        when 'capabilities'
          type_error = check_results[:errors][:capabilities]
        else
          type_error = {}
      end
      error_key = type_error.keys.first
      folders_stack = error_key.split('/')
      # process this
      folders_stack
    end
  end

  def get_l1_hash(columns)
    l1_hash = {}
    columns.each{|c| l1_hash[c]={} }
    l1_hash
  end

  def get_row_content(column, v, types, data)
    # column can be summary, pruduct1, ..
    v[:value] = 8
    v[:conflict] = false
    v[:conflicts_with] = []
    v[:conflict_message] = nil
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

