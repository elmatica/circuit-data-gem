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

#### `Circuitdata.dereferenced_schema`

This returns the JSON schema used internally to validate the Circuit Data information. It
returns the schema without any usage of `$ref` so that it can be utilized without any knowledge of the internal paths.

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

### Validation

To validate a CircuitData JSON file the `Validator` can be used. This will check that a file matches the schema defined in the CircuitData language as well as logical issues. An example of a logical issue is missing layers in the layers list for a product.

The following is an example of using the `Validator`:

```
validator = Circuitdata::Validator.new(json_file_contents)
if !validator.valid?
  puts validator.errors.inspect
end
# ...
```

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
