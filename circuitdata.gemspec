$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "circuitdata/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name = "circuitdata"
  s.version = Circuitdata::VERSION
  s.authors = ["Andreas Lydersen", "Maximilian Brosnahan", "Benjamin Mwendwa"]
  s.email = ["andreas.lydersen@ntty.com"]
  s.homepage = "http://circuitdata.org"
  s.summary = "Basic test and comparison of JSON files agains the CircuitData JSON schema and each other"
  s.description = "This gem provides you with functions to work with the CricuitData language. Run files against the schema, check their compatibility agains each other compare multiple files to find conflicts."
  s.license = "MIT"

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]

  s.required_ruby_version = ">= 2.3"
  s.add_dependency "json-schema", "2.8.0"
  s.add_dependency "activesupport", "> 5.1", "< 7"
  s.add_dependency "terminal-table", "~> 1.8.0"
  s.add_development_dependency "rake", "~> 13.0"
  s.add_development_dependency "rspec", "~> 3.7"
  s.add_development_dependency "byebug", "~> 10.0"
  s.add_development_dependency "guard", "~> 2.14.2"
  s.add_development_dependency "guard-rspec", "~> 4.7"
  s.add_development_dependency "hashdiff", "~> 0.3.7"
  s.add_development_dependency "rspec_junit_formatter", "~> 0.4.1"
  s.add_development_dependency "rufo", "~> 0.12"
end
