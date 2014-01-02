# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'unitypods/version'

Gem::Specification.new do |spec|
  spec.name          = "unitypods"
  spec.version       = Unitypods::VERSION
  spec.authors       = ["Nicola Brisotto"]
  spec.email         = ["nicola@fungostudios.com"]
  spec.description   = %q{Provide a command line tool to integrate pods into a unity project}
  spec.summary       = %q{Provide a command line tool to integrate pods into a unity project}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec", "~> 2.14.1"
  spec.add_runtime_dependency "cocoapods", "~> 0.28.0"
  spec.add_runtime_dependency "thor", "~> 0.18.0"
end
