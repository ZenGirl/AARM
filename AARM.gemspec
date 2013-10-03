# coding: utf-8
$LOAD_PATH.unshift File.expand_path('../lib', __FILE__)
require 'rack/version'

Gem::Specification.new do |spec|
  spec.name          = "Rack.AARM.Middleware"
  spec.version       = Rack::AARM::VERSION
  spec.authors       = ["Kimberley Scott"]
  spec.email         = %w(kscott@localdirectories.com)
  spec.description   = %q{Authentication and Authorisation rack Middleware}
  spec.summary       = %q{Gem to automagically authenticate and authorise requests to routes }
  spec.homepage      = "http://localdirectories.com/apis"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = %w(lib)

  # Development dependencies
  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "cucumber"
  spec.add_development_dependency "rack-test"
  spec.add_development_dependency "factory_girl"
  spec.add_development_dependency "fuubar"
  spec.add_development_dependency "awesome_print"
  # guard gems
  spec.add_development_dependency "guard"
  spec.add_development_dependency "guard-rspec"
  # spork gems
  spec.add_development_dependency "spork"
  spec.add_development_dependency "guard-spork"


  # Production dependencies
  spec.add_runtime_dependency "json"
  spec.add_runtime_dependency "rack_csrf"
  spec.add_runtime_dependency "activerecord", ">= 4.0.0"
  spec.add_runtime_dependency "mysql2", ">= 0.3.13"

end
