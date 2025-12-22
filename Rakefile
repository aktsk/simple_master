# frozen_string_literal: true

require "bundler/setup"
require "rspec/core/rake_task"

RSpec::Core::RakeTask.new(:spec)
RSpec::Core::RakeTask.new(:rails_sample_spec) do |task|
  task.pattern = "examples/rails_sample/spec/**/*_spec.rb"
  task.rspec_opts = "--require ./examples/rails_sample/spec/spec_helper --default-path examples/rails_sample/spec"
end

task default: :spec
