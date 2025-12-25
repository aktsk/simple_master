# frozen_string_literal: true

ENV["RAILS_ENV"] = "test"
ENV["DATABASE_URL"] ||= "sqlite3::memory:"

require "bundler/setup"
require "rspec"
require "rails"
require "active_record/railtie"
require "active_support/time"
require "factory_bot"
require "logger"
require "simple_master"

require_relative "../config/environment"

ApplicationMaster.prepend(SimpleMaster::Master::Editable)

ActiveRecord::Base.establish_connection(:test)
ActiveRecord::Base.logger = Rails.logger
ActiveRecord::Base.logger.level = Logger::WARN
ActiveRecord::Migration.verbose = false

load File.expand_path("../db/schema.rb", __dir__)
FactoryBot.definition_file_paths = [
  File.expand_path("factories", __dir__),
]
FactoryBot.find_definitions

RSpec.configure do |config|
  config.order = :random
  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
  config.include FactoryBot::Syntax::Methods
  config.around do |example|
    dataset = SimpleMaster::Storage::Dataset.new(table_class: SimpleMaster::Storage::TestTable)
    SimpleMaster.use_dataset(dataset) do
      example.run
    end
    RequestStore.clear!
  end
end
