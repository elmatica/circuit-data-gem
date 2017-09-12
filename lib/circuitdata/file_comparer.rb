class Circuitdata::FileComparer
  def initialize(files_hash, validate_origins=false)
    @files_hash = files_hash
    @columns = ['summary']
    @rows = []
    # Final hash
    @fh = { error: false, errormessage: nil, productname: nil, columns: @columns, mastercolumn: nil, rows: @rows }

    # final return
    @ra = {
      error: false,
      errormessage: "",
      summary: {},
      conflicts: {},
      product: nil,
      columns: [],
      mastercolumn: nil,
      rows: []
    }
    @validate_origins = validate_origins
  end

  # def deep_traverse(&block)
  #   stack = self.map{ |k,v| [ [k], v ] }
  #   while not stack.empty?
  #     key, value = stack.pop
  #     yield(key, value)
  #     if value.is_a? Hash
  #       value.each{ |k,v| stack.push [ key.dup << k, v ] }
  #     end
  #   end
  # end

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
    @files_hash.each_with_index do |(k, v), i|
      @columns << k.to_s
      # read content
      error, error_msg, file_content = Circuitdata.read_json(v)
      @fh[:mastercolumn] = k.to_s if i == 0 # the first item

      # Get details about each v
      nh[k] = {data: file_content, has: {} } # init
      nh[k][:has][:products], nh[k][:has][:stackup], nh[k][:has][:profile_default], nh[k][:has][:profile_restricted], nh[k][:has][:profile_enforced], nh[k][:has][:capabilities], nh[k][:has][:product] = Circuitdata.content(file_content)
      

      puts "Columns: #{@columns}"
      puts "Error: #{error}"
      puts "Error Msg: #{error_msg}"
      puts "File_content: #{file_content}"
    end

    puts "\n\n\nEXTENDED HASH: #{nh}\n\n\n"
    puts "\n\n\nFINAL HASH: #{@fh}\n\n\n"

    # Function to interact with nh here - adding it later


    #====================== Start of older code ======================

    # Prepare the return
    ra = @ra
    
    # extend the hash that is received
    nh = {}
    @files_hash.each do |fhk, fhv|
      nh[fhk] = {
        orig: fhv,
        parsed: nil,
        content: nil,
        has: {}
      }
      # READ THE CONTENT
      ra[:error], ra[:errormessage], nh[fhk][:content] = Circuitdata.read_json(fhv)
      ra[:summary] = {} if ra[:error]
      ra[:conflicts] = {} if ra[:error]
      return ra if ra[:error]
      # VALIDATE THE FILES
      if @validate_origins
        ra[:error], ra[:errormessage], validationserrors = Circuitdata.validate(nh[fhk][:content])
        ra[:summary] = {} if ra[:error]
        ra[:conflicts] = {} if ra[:error]
        return ra if ra[:error]
      end


      # SET THE PRODUCT NAME
      nh[fhk][:has][:products], nh[fhk][:has][:stackup], nh[fhk][:has][:profile_default], nh[fhk][:has][:profile_restricted], nh[fhk][:has][:profile_enforced], nh[fhk][:has][:capabilities], nh[fhk][:has][:product] = Circuitdata.content(nh[fhk][:content])
      unless nh[fhk][:has][:product].nil?
        #Circuitdata.iterate(nh[fhk][:content])

        #root_node = Tree::TreeNode.new("ROOT", "Root Content")
        #root_node.print_tree

        ra[:product] = nh[fhk][:has][:product] if ra[:product].nil?
        if nh[fhk][:has][:product] != ra[:product]
          ra[:error] = true
          ra[:errormessage] = "Your files contains several different product names"
          ra[:summary] = {}
          ra[:conflicts] = {}
          return ra
        end
        ra[:mastercolumn] = fhk if ra[:mastercolumn].nil?
      end

      # THIS IS WHERE I NEED THINGS TO HAPPEN

    end

    # RETURN IF THERE IS NO PRODUCT
    if ra[:mastercolumn].nil?
      ra[:error] = true
      ra[:errormessage] = "none of the files contains a product"
      ra[:summary] = {}
      ra[:conflicts] = {}
      return ra
    end

    {
      current_level: 0,
      current_key: nil,

    }
    # Populate the master column
    #Circuitdata.iterate(@files_hash[ra[:mastercolumn].to_sym])
    #ra[:summary] = productjson[:open_trade_transfer_package][:products][ra[:product]][:printed_circuits_fabrication_data]

    #test = {}
    #Circuitdata.save_pair(productjson[:open_trade_transfer_package][:products][ra[:product]][:printed_circuits_fabrication_data], test)
    #puts test
    # Populate the product rows
    #productjson[:open_trade_transfer_package]["products"][ra[:product]]["printed_circuits_fabrication_data"].each do |key, value|
    #  if value.is_a? Hash
    #    value.each do |subkey, subvalue|
    #      ra[:rows][]
    #end

    # Do comparisons
    #number = 1
    #@files_hash.each do |key, value|
  #    unless key.to_s == productfile
  #      #puts Circuitdata.compatibility_checker( productjson, value, false )
  #      number += 1
  #    end
  #  end
    #puts JSON.pretty_generate(ra)
    #puts JSON.pretty_generate(nh)
    return @ra
    #====================== Start of older code ======================
    # return @fh
  end
end