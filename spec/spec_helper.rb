# frozen_string_literal: true

ENV["DATABASE_URL"] ||= "sqlite3::memory:"

require "bundler/setup"
require "rspec"
require "rails"
require "active_record/railtie"
require "active_support/time"
require "factory_bot"
require "logger"
require "simple_master"

# Boot sample Rails app
require_relative "../examples/rails_sample/lib/json_loader"
require_relative "../examples/rails_sample/config/environment"

ActiveRecord::Base.establish_connection(:test)
ActiveRecord::Base.logger = Rails.logger
ActiveRecord::Base.logger.level = Logger::WARN
ActiveRecord::Migration.verbose = false

# Load schema and models
load File.expand_path("../examples/rails_sample/db/schema.rb", __dir__)
%w(
  application_record
  player
  player_item
  weapon
  armor
  potion
  level
  enemy
  reward
).each do |model|
  require File.expand_path("../examples/rails_sample/app/models/#{model}", __dir__)
end

# Test support helpers
require_relative "support/dataset_helper" if File.exist?(File.expand_path("support/dataset_helper.rb", __dir__))
FactoryBot.find_definitions

I18n.available_locales = [:en, :ja]

RSpec.configure do |config|
  config.order = :random
  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
  config.include DatasetHelper
  config.include FactoryBot::Syntax::Methods
  config.after { RequestStore.clear! }
end
