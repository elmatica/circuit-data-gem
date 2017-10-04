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


#### `Circuitdata.compatibility_checker`

Test one file against the schema
```ruby
Circuitdata.compatibility_checker('testfile-product.json')
```
When valid gives:
```ruby
{
  :error => false,
  :errormessage => "",
  :validationserrors => {},
  :restrictederrors => {},
  :enforcederrors => {},
  :capabilitieserrors => {}
}
```

Test two files up against each other (one must be a product file).
```ruby
Circuitdata.compatibility_checker('testfile-product.json','testfile-profile-restricted.json')
```

When invalid results in:
```ruby
{
  :error => true,
  :errormessage => "The product to check did not meet the requirements",
  :validationserrors => {},
  :restrictederrors => {
    "#/open_trade_transfer_package/products/testproduct/printed_circuits_fabrication_data/board/thickness" => [
      "of type number matched the disallowed schema"
      ]
  },
  :enforcederrors => {},
  :capabilitieserrors => {}
}
```

Turn off validation against the schema
```ruby
Circuitdata.compatibility_checker( 'testfile-product.json', 'testfile-profile-restricted.json', false )
```
 Gives:
```ruby
{
  :error => true,
  :errormessage => "The product to check did not meet the requirements",
  :validationserrors => {},
  :restrictederrors => {
    "#/open_trade_transfer_package/products/testproduct/printed_circuits_fabrication_data/board/thickness" => ["of type number matched the disallowed schema"]
  },
  :enforcederrors => {},
  :capabilitieserrors => {}
}

```


#### `Circuitdata.compare_files`

Run a test with several files against each other and get a complete list of values and conflicts, and a summary
 ```ruby
 product1 = File.join(__dir__, 'test/test_data/test_product1.json')
 profile_restricted = File.join(__dir__, 'test/test_data/testfile-profile-restricted.json')
 profile_default = File.join(__dir__, 'test/test_data/testfile-profile-default.json')
 file_hash = {product1: product1, restricted: profile_restricted, default: profile_default}

 Circuitdata.compare_files(file_hash, true)
 ```

 Results in:
 ```ruby
 {
  :error=>false,
  :message=>nil,
  :conflict=>false,
  :product_name=>"testproduct",
  :columns=>[
    :summary,
    :product1,
    :restricted,
    :default
  ],
  :master_column=>nil,
  :rows=>{
    :rigid_conductive_layer=>{
      :count=>{
        :product1=>{
          :value=>11,
          :conflict=>false,
          :conflicts_with=>[],
          :conflict_message=>[]
        },
        :restricted=>{
          :value=>nil,
          :conflict=>false,
          :conflicts_with=>[],
          :conflict_message=>[]
        },
        :default=>{
          :value=>nil,
          :conflict=>false,
          :conflicts_with=>[],
          :conflict_message=>[]
        },
        :summary=>{
          :value=>11,
          :conflict=>false,
          :conflicts_with=>[:product1],
          :conflict_message=>[]
        }
      }
      # ...
    }
  }
}
```

## License
The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
