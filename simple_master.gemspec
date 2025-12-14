# frozen_string_literal: true

require_relative "lib/simple_master/version"

Gem::Specification.new do |spec|
  spec.name          = "simple_master"
  spec.version       = SimpleMaster::VERSION
  spec.authors       = ["Jingyuan Zhao"]
  spec.email         = ["jingyuan.zhao@aktsk.jp"]

  spec.summary       = "In-memory master data cache with an ActiveRecord-like API"
  spec.description   = "SimpleMaster loads master tables into memory, builds associations, and offers a small DSL for master data models."
  spec.homepage      = "https://github.com/aktsk/simple_master"
  spec.license       = "MIT"
  spec.required_ruby_version = ">= 3.1"

  spec.files = Dir.chdir(__dir__) {
    Dir["lib/**/*"]
  }
  spec.require_paths = ["lib"]

  spec.add_dependency "activerecord", ">= 7.0"
  spec.add_dependency "activesupport", ">= 7.0"
  spec.add_dependency "request_store", ">= 1.0"

  spec.metadata['rubygems_mfa_required'] = 'true'
end
