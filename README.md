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

#### `Circuitdata.dereferenced_schema`

This returns the JSON schema used internally to validate the Circuit Data information. It
returns the schema without any usage of `$ref` so that it can be utilized without any knowledge of the internal paths.

#### `Circuitdata::Profile.schema`

Returns a subset of the Circuit Data schema that relates to profiles. This is a schema without any `$ref`s.
#### `Circuitdata::Profile.questions`
Returns a list of grouped questions that can be used for populating an input interface related to profiles.

Example output:
```ruby
[
  {
    id: :rigid_conductive_layer,
    name: 'Rigid conductive layer',
    questions: [
      {
        code: :copper_foil_roughness,
        name: 'Copper foil roughness',
        defaults: {
          descriptor: {
            type: "string",
            enum: ["S", "L", "V"],
            uom: ["um"],
            description: "The roughness of the copper foil."
          },
          path: "/open_trade_transfer_package/profiles/defaults/printed_circuits_fabrication_data/rigid_conductive_layer/copper_foil_roughness"
        }
      },
    ]
  }
  # ...
]
```
## License
The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
