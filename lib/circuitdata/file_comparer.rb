class Circuitdata::FileComparer
  def initialize(files_hash, validate_origins=false)
    @files_hash = files_hash
    @validate_origins = validate_origins
    @columns = ['summary']
    @rows = {}
    # Final hash
    @fh = {error: false, message: nil, productname: nil, columns: nil, master_column: nil, rows: nil}
  end

  def compare
    # Initial check
    unless @files_hash.is_a? Hash
      @fh[:error] = true
      @fh[:errormessage] = 'You have to feed this function with a hash of names and hashes'
      return @fh
    end

    # Process the hashes
    master_product = nil
    # extend the hash that is received - New Hash
    nh = {}
    products_array = []
    @files_hash.each_with_index do |(k, v), i|
      # puts "\n\n====================="
      # puts "Working on file: #{k}"
      @fh[:master_column] = k.to_s  # if its the first item

      # read content
      error, error_msg, file_content = Circuitdata.read_json(v)
      # puts "Error: #{error}"
      # puts "Error Msg: #{error_msg}"
      # Get details about the file_content
      products, types = Circuitdata.get_data_summary(file_content)
      # puts "products: #{products}"
      # puts "types: #{types}"
      products_array.push(*products) # add products to tracking array
      # populate the new_hash to be used later
      nh[k] = {types: types, products: products, data: file_content}
      # puts "New Hash: #{nh}"
      # puts "=====================\n\n"
    end

    puts "\n\n\nEXTENDED HASH: #{nh}\n\n\n"

    # check if the files content meet the requirements
    if valid_product?(products_array)
      puts "\n\nFiles are valid"

      # generate summary insert into rows for each array
      master_json = nh&.dig(@fh[:master_column].to_sym, :data)
      nh.each do |k, v|
        @columns << k
        types = v[:types]
        products = v[:products]
        puts "\n\n\n*********************"
        puts "Key: #{k}"
        puts "Types: #{types}"
        puts "products: #{products}"

        puts "v: #{v}"
        data = v[:data]
        puts "data: #{data}"

        check_results = Circuitdata.compatibility_checker(master_json, data, false)
        puts "\n\n\nCHECK RESULTS: #{check_results}\n\n\n"
        # from the results, we will populate the rows

        folders = check_results[:capabilitieserrors].keys.first
        folders_array = []
        folders_array = folders.split('/') if folders
        if folders_array[2] == 'products'
          # this is from the product
          if (folders_array[4] = 'printed_circuits_fabrication_data')
            folder, key = folders_array[5].to_sym, folders_array[6].to_sym

            puts "\n\nFolder: #{products}"
            puts "Key: #{key}\n\n"
            row_folder = @rows&.dig(folder) || @rows[folder] = {}
            row_key = row_folder&.dig(key) || row_folder[key] = {}
            # Other checks here.
            # This should be done via a function
            row_key[:summary] = {
                value: 'V',
                conflict: true,
                conflicts_with: ['product2', 'restriced'],
                conflict_message: 'Value V is not allowed'
            }
          end
        end if folders_array.any?
        puts "*******************\n\n\n"
      end
    end

    @fh[:columns] = @columns
    @fh[:rows] = @rows

    puts "\n\n\nFINAL HASH: #{@fh}\n\n\n"

    return @fh
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

