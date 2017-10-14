$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "circuitdata/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "circuitdata"
  s.version     = Circuitdata::VERSION
  s.authors     = ["Andreas Lydersen"]
  s.email       = ["andreas.lydersen@ntty.com"]
  s.homepage    = "http://circuitdata.org"
  s.summary     = "This gem allows you to do basic test and comparison of JSON files agains the CircuitData JSON schema"
  s.description = "This gem allows you to do basic test and comparison of JSON files agains the CircuitData JSON schema"
  s.license     = "MIT"

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]

  s.required_ruby_version     = ">= 2.3"
  s.add_dependency "json-schema", "~> 2.8"
  s.add_development_dependency "rake", "~> 12.1"
  s.add_development_dependency "minitest", "~> 5.10"
  s.add_development_dependency 'activesupport', '~> 4.2'
end
