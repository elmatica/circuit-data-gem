class Circuitdata::FileComparer
  def initialize(files_hash, validate_origins=false)
    @files_hash = files_hash
    @validate_origins = validate_origins
    @columns = ['summary']
    @rows = []
    # Final hash
    @fh = {error: false, message: nil, productname: nil, columns: @columns, master_column: nil, rows: @rows}
  end

  def compare
    # Initial check
    unless @files_hash.is_a? Hash
      @fh[:error] = true
      @fh[:errormessage] = "You have to feed this function with a hash of names and hashes"
      return @fh
    end

    # Process the hashes
    master_product = nil
    # extend the hash that is received - New Hash
    nh = {}
    product_names = []
    @files_hash.each_with_index do |(k, v), i|
      puts "\n\n====================="
      puts "Working on file: #{k}"
      @fh[:master_column] = k.to_s  # if its the first item

      # read content
      error, error_msg, file_content = Circuitdata.read_json(v)
      puts "Error: #{error}"
      puts "Error Msg: #{error_msg}"
      # Get details about the file_content
      products, types = check_data(file_content)
      puts "products: #{products}"
      puts "types: #{types}"
      product_names.push(*products) # add products to tracking array
      # populate the new_hash to be used later
      nh[k] = {type: types, products: products, data: file_content}
      puts "New Hash: #{nk}"
      puts "=====================\n\n"
    end

    puts "\n\n\nEXTENDED HASH: #{nh}\n\n\n"
    puts "\n\n\nFINAL HASH: #{@fh}\n\n\n"

    if valid_product?(products_array) # check if the files content meet the requirements
      puts "Files are valid"

      # generate summary insert into rows for each array
      master_json = @nh.dig(master_column.to_sym, :data)
      @nh.each do |k, v|
        types = v[:types]
        products = v[:products]
        data = v[:data]

        check_results = Circuitdata.compatibility_checker(master_json, data, false)
        pp check_results
        # from the results, we will populate the rows

      end
    end

    return @fh
  end

  def check_data(data)
    types = []
    wrapper = data.dig(:open_trade_transfer_package)
    types << 'profile_enforced' unless wrapper.dig(:profiles, :enforced).nil?
    types << 'profile_restricted' unless wrapper.dig(:profiles, :restricted).nil?
    types << 'profile_defaults' unless wrapper.dig(:profiles, :defaults).nil?
    types << 'capabilities' unless wrapper.dig(:capabilities).nil?

    products = wrapper.dig(:products) if wrapper
    product_names = products.keys # this will return all the product names
    # loop through the products
    products.each do |k, v|
      if v.dig(:stackup, :specification_level) == 'specified' && !v.dig(:stackup, :specification_level, :specified).nil?
        types << 'stackup'
      end
    end unless products.nil?

    product_names.uniq, types
  end

  def valid_product?(products_array)
    if products_array.uniq.count > 1
      @fh[:error] = true
      @fh[:message] = "Your files contains several different product names"
      return false # validation fails because of different product names
    end
    if products_array.empty?
      @fh[:error] = true
      @fh[:message] = "None of the files contains a product"
      return false # c=validation fails because there are no products
    end
    true
  end
end

