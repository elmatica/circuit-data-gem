class Circuitdata::FileComparer
  def initialize(files_hash, validate_origins=false)
    @files_hash = files_hash
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

  def compare
    # Prepare the return
    filehash = @files_hash
    validate_origins = @validate_origins
    ra = @ra

    #parsedfiles
    unless filehash.is_a? Hash
      ra[:error] = true
      ra[:errormessage] = "You have to feed this function with a hash of names and hashes"
      return ra
    end

    # extend the hash that is received
    nh = {}
    filehash.each do |fhk, fhv|
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
      if validate_origins
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
    #Circuitdata.iterate(filehash[ra[:mastercolumn].to_sym])
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
    #filehash.each do |key, value|
  #    unless key.to_s == productfile
  #      #puts Circuitdata.compatibility_checker( productjson, value, false )
  #      number += 1
  #    end
  #  end
    #puts JSON.pretty_generate(ra)
    #puts JSON.pretty_generate(nh)
    return ra
  end
end