# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'durable_call/version'

Gem::Specification.new do |spec|
  spec.name          = "durable_call"
  spec.version       = DurableCall::VERSION
  spec.authors       = ["Alexander Pavlenko"]
  spec.email         = ["apavlenko@mirantis.com"]
  spec.description   = %q{Invoke methods DRY and safely with parameterized retries, timeouts and logging}
  spec.summary       = %q{Durable methods invocation}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "coveralls"
end
