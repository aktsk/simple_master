# frozen_string_literal: true

require_relative "boot"

require "rails"
require "active_record/railtie"
require "action_controller/railtie"
require "simple_master"

module Dummy
  class Application < Rails::Application
    config.root = File.expand_path("..", __dir__)
    config.eager_load = false
    config.logger = Logger.new($stdout)
    config.logger.level = Logger::WARN
    config.active_support.test_order = :random
    config.hosts = nil
    config.autoload_paths << Rails.root.join("lib")
  end
end
