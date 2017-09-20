# Circuitdata
This gem provides helper functions that allows you to do schema checks and control files up against each other according to the [CircuitData Language](https://circuitdata.org)

## Installation
Add this line to your application's Gemfile:

```ruby
gem 'circuitdata'
```

And then execute:
```bash
$ bundle
```

Or install it yourself as:
```bash
$ gem install circuitdata
```

## Usage
If not in rails
```
require 'circuitdata'
```

### Commands

```
2.3.0 :001 > require 'circuitdata'
 => true
2.3.0 :002 > # Test one file against the schema
2.3.0 :004 >   Circuitdata.compatibility_checker( 'testfile-product.json')
 => {:error=>false, :errormessage=>"", :validationserrors=>{}, :restrictederrors=>{}, :enforcederrors=>{}, :capabilitieserrors=>{}}
2.3.0 :005 >
2.3.0 :006 >   # Test two files up against each other (one must be a product file)
2.3.0 :007 >   Circuitdata.compatibility_checker( 'testfile-product.json', 'testfile-profile-restricted.json' )
 => {:error=>true, :errormessage=>"The product to check did not meet the requirements", :validationserrors=>{},  :restrictederrors=>{"#/open_trade_transfer_package/products/testproduct/printed_circuits_fabrication_data/board/thickness"=>["of type number matched the disallowed schema"]}, :enforcederrors=>{}, :capabilitieserrors=>{}}
2.3.0 :005 >
2.3.0 :009 > # Turn off validation against the schema
2.3.0 :008 > Circuitdata.compatibility_checker( 'testfile-product.json', 'testfile-profile-restricted.json', false )
 => {:error=>true, :errormessage=>"The product to check did not meet the requirements", :validationserrors=>{}, :restrictederrors=>{"#/open_trade_transfer_package/products/testproduct/printed_circuits_fabrication_data/board/thickness"=>["of type number matched the disallowed schema"]}, :enforcederrors=>{}, :capabilitieserrors=>{}}
2.3.0 :005 > # Run a test with several files against each other and get a complete list of values and conflicts, and a summary
2.3.0 :006 > product1 = File.join(File.dirname(__FILE__), 'test/test_data/test_product1.json')
 => "./test/test_data/test_product1.json"
2.3.0 :007 > profile_restricted = File.join(File.dirname(__FILE__), 'test/test_data/testfile-profile-restricted.json')
 => "./test/test_data/testfile-profile-restricted.json"
2.3.0 :008 > profile_default = File.join(File.dirname(__FILE__), 'test/test_data/testfile-profile-default.json')
 => "./test/test_data/testfile-profile-default.json"
2.3.0 :009 > file_hash = {product1: product1, restricted: profile_restricted, default: profile_default}
 => {:product1=>"./test/test_data/test_product1.json", :restricted=>"./test/test_data/testfile-profile-restricted.json", :default=>"./test/test_data/testfile-profile-default.json"}
2.3.0 :010 > Circuitdata.compare_files(file_hash, true)
 => {:error=>false, :message=>nil, :conflict=>false, :product_name=>"testproduct", :columns=>[:summary, :product1, :restricted, :default], :master_column=>nil, :rows=>{:rigid_conductive_layer=>{:count=>{:product1=>{:value=>11, :conflict=>false, :conflicts_with=>[], :conflict_message=>[]}, :restricted=>{:value=>nil, :conflict=>false, :conflicts_with=>[], :conflict_message=>[]}, :default=>{:value=>nil, :conflict=>false, :conflicts_with=>[], :conflict_message=>[]}, :summary=>{:value=>11, :conflict=>false, :conflicts_with=>[:product1], :conflict_message=>[]}}, :minimum_external_track_width=>{:product1=>{:value=>0.14, :conflict=>false, :conflicts_with=>[], :conflict_message=>[]}, :restricted=>{:value=>nil, :conflict=>false, :conflicts_with=>[], :conflict_message=>[]}, :default=>{:value=>nil, :conflict=>false, :conflicts_with=>[], :conflict_message=>[]}, :summary=>{:value=>0.14, :conflict=>false, :conflicts_with=>[:product1], :conflict_message=>[]}}, :minimum_external_spacing_width=>{:product1=>{:value=>0.14, :conflict=>false, :conflicts_with=>[], :conflict_message=>[]}, :restricted=>{:value=>nil, :conflict=>false, :conflicts_with=>[], :conflict_message=>[]}, :default=>{:value=>nil, :conflict=>false, :conflicts_with=>[], :conflict_message=>[]}, :summary=>{:value=>0.14, :conflict=>false, :conflicts_with=>[:product1], :conflict_message=>[]}}, :copper_foil_roughness=>{:product1=>{:value=>"L", :conflict=>false, :conflicts_with=>[], :conflict_message=>[]}, :restricted=>{:value=>nil, :conflict=>false, :conflicts_with=>[], :conflict_message=>[]}, :default=>{:value=>nil, :conflict=>false, :conflicts_with=>[], :conflict_message=>[]}, :summary=>{:value=>"L", :conflict=>false, :conflicts_with=>[:product1], :conflict_message=>[]}}}, :legend=>{:color=>{:product1=>{:value=>nil, :conflict=>false, :conflicts_with=>[], :conflict_message=>[]}, :restricted=>{:value=>nil, :conflict=>false, :conflicts_with=>[], :conflict_message=>[]}, :default=>{:value=>"white", :conflict=>false, :conflicts_with=>[], :conflict_message=>[]}, :summary=>{:value=>"white", :conflict=>false, :conflicts_with=>[], :conflict_message=>[]}}}, :array=>{:fiducials_number=>{:product1=>{:value=>nil, :conflict=>false, :conflicts_with=>[], :conflict_message=>[]}, :restricted=>{:value=>nil, :conflict=>false, :conflicts_with=>[], :conflict_message=>[]}, :default=>{:value=>3, :conflict=>false, :conflicts_with=>[], :conflict_message=>[]}, :summary=>{:value=>3, :conflict=>false, :conflicts_with=>[], :conflict_message=>[]}}, :fiducials_shape=>{:product1=>{:value=>nil, :conflict=>false, :conflicts_with=>[], :conflict_message=>[]}, :restricted=>{:value=>nil, :conflict=>false, :conflicts_with=>[], :conflict_message=>[]}, :default=>{:value=>"circle", :conflict=>false, :conflicts_with=>[], :conflict_message=>[]}, :summary=>{:value=>"circle", :conflict=>false, :conflicts_with=>[], :conflict_message=>[]}}, :breakaway_method=>{:product1=>{:value=>nil, :conflict=>false, :conflicts_with=>[], :conflict_message=>[]}, :restricted=>{:value=>nil, :conflict=>false, :conflicts_with=>[], :conflict_message=>[]}, :default=>{:value=>"routing", :conflict=>false, :conflicts_with=>[], :conflict_message=>[]}, :summary=>{:value=>"routing", :conflict=>false, :conflicts_with=>[], :conflict_message=>[]}}, :mouse_bites=>{:product1=>{:value=>nil, :conflict=>false, :conflicts_with=>[], :conflict_message=>[]}, :restricted=>{:value=>nil, :conflict=>false, :conflicts_with=>[], :conflict_message=>[]}, :default=>{:value=>true, :conflict=>false, :conflicts_with=>[], :conflict_message=>[]}, :summary=>{:value=>true, :conflict=>false, :conflicts_with=>[], :conflict_message=>[]}}}}} 
```

## License
The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
