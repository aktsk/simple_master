# frozen_string_literal: true

require "active_support/dependencies"
require "active_record"
require "logger"
require "simple_master/version"

module SimpleMaster
  EMPTY_ARRAY = [].freeze
  EMPTY_HASH = {}.freeze

  def self.logger
    if defined?(Rails) && Rails.respond_to?(:logger) && Rails.logger
      Rails.logger
    else
      @logger ||= Logger.new($stdout)
    end
  end

  def self.init(for_test: false)
    is_database_available = database_available?
    unless is_database_available
      SimpleMaster.logger.warn "DB not connected. SimpleMaster will not initialize associations to ActiveRecord."
    end

    yield if block_given?

    targets.each { |klass| klass.init(is_database_available, for_test: for_test) }
  end

  def self.targets
    Master.descendants.reject(&:abstract_class)
  end

  def self.database_available?
    # Raises an error if the DB is missing
    ::ActiveRecord::Base.connection.verify!

    true
  rescue
    false
  end

  def self.use_dataset(dataset)
    former_dataset = $current_dataset
    $current_dataset = dataset
    yield
  ensure
    $current_dataset = former_dataset
  end
end

require "simple_master/active_record"
require "simple_master/loader"
require "simple_master/schema"
require "simple_master/storage"
require "simple_master/master"

class ActiveRecord::Associations::Preloader::Association
  prepend SimpleMaster::ActiveRecord::PreloaderAssociationExtension
end
