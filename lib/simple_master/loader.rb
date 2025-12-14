# frozen_string_literal: true

module SimpleMaster
  class Loader
    attr_reader :options

    def initialize(options = {})
      @options = options
    end

    # Returns if records are updated in table.
    def load_records(table)
      klass = table.klass
      fail "Load target not available." unless klass.base_class?

      raw = read_raw(table)

      new_digest = table.diff.nil? ? raw.hash : "#{raw.hash}/#{table.diff.hash}"
      if new_digest == table.digest
        return false
      end

      table.digest = new_digest
      table.all = build_records(klass, raw).freeze
      globalize(table)

      table.apply_diff

      table.update_sub_tables

      klass.reset_object_cache

      true
    end

    # Interface for loader loading raw data, for building records and table digest.
    def read_raw(table)
      fail NotImplementedError
    end

    # Interface for building records from raw data.
    def build_records(klass, raw)
      fail NotImplementedError
    end

    def globalize(table)
      return unless options[:globalize_proc]
      table.all = options[:globalize_proc].call(table.klass, table.all)
    end
  end
end

require "simple_master/loader/dataset_loader"
require "simple_master/loader/marshal_loader"
require "simple_master/loader/query_loader"
