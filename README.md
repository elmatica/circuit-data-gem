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
```

## License
The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
