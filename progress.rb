# Then run compare_files
product1 = File.path('/Users/benjamin/Downloads/commodity.live/gem/product1.json')
product2 = File.path('/Users/benjamin/Downloads/commodity.live/gem/product2.json')
profile_restricted = File.path('/Users/benjamin/Downloads/commodity.live/gem/profile_restricted.json')

Circuitdata.compare_files({product1: product1, product2: product2, restricted: profile_restricted}, true)

# Retuning now
{
    :error=>false, 
    :errormessage=>"", 
    :summary=>{}, 
    :conflicts=>{}, 
    :product=>"testproduct", 
    :columns=>[], 
    :mastercolumn=>:product1, 
    :rows=>[]
}

# Should return
{
    error: false,
    errormessage: "",
    productname: 'testproduct',
    columns: ["summary", "product1", "product2", "restricted"],
    mastercolumn: "product1",
    rows: [
        {
        folder: "rigid_conductive_layer",
        key: "count",
        summary: {
            value: 8,
            conflict: false,
            conflicts_with: [],
            conflict_message: nil
        },
        product1: {
            value: 8,
            conflict: false,
            conflicts_with: [],
            conflict_message: nil
        },
        product2: {
            value: nil,
            conflict: false,
            conflicts_with: [],
            conflict_message: nil
        },
        restricted: {
            value: nil,
            conflict: false,
            conflicts_with: [],
            conflict_message: nil
        }
        },
        {
        folder: "rigid_conductive_layer",
        key: "copper_foil_roughness",
        summary: {
            value: "V",
            conflict: true,
            conflicts_with: ["product2", "restriced"],
            conflict_message: "Value V is not allowed"
        },
        product1: {
            value: nil,
            conflict: false,
            conflicts_with: [],
            conflict_message: nil
        },
        product2: {
            value: "V",
            conflict: true,
            conflicts_with: ["restricted"],
            conflict_message: "Value \"V\" is now allowed"
        },
        restricted: {
            value: "V",
            conflict: false,
            conflicts_with: ["product2"],
            conflict_message: "Value \"V\" is now allowed"
        }
        }
    ]
}