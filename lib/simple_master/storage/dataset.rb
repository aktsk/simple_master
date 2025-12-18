# frozen_string_literal: true

require "simple_master/storage/table"
require "simple_master/storage/test_table"

module SimpleMaster
  module Storage
    class Dataset
      require "objspace"

      class << self
        def after_load_procs
          @after_load_procs ||= []
        end

        def after_load(&proc)
          after_load_procs << proc
        end

        def run_after_load
          after_load_procs.each(&:call)
        end
      end

      DEFAULT_TABLE = Table
      DEFAULT_LOADER = Loader::QueryLoader

      attr_reader :table_class
      attr_reader :loader
      attr_reader :diff
      attr_accessor :tables
      attr_accessor :cache
      attr_accessor :load_targets

      def initialize(table_class: DEFAULT_TABLE, loader: nil)
        @table_class = table_class
        @loader = loader || DEFAULT_LOADER.new
        @diff = {}

        initialize_cache
      end

      def initialize_cache
        self.tables = Hash.new { |hash, klass| hash[klass] = table_class.new(klass, self, loader) }.compare_by_identity
        self.cache = {}
      end

      def table(klass)
        @tables[klass]
      end

      def reload
        if table_class <= SimpleMaster::Storage::OndemandTable
          unload
        else
          load
        end
      end

      def load
        memsize do
          cache.clear
          targets = @load_targets || SimpleMaster.targets

          tables = targets.map(&:base_class).uniq.map { table(_1) }

          timer("MasterData load") do
            tables.each(&:load_records)
          end

          timer("MasterData cache update") do
            SimpleMaster.use_dataset(self) do
              tables.each(&:update_class_method_cache)
              tables.each(&:tap_instance_methods)
              tables.each(&:freeze_all)
            end
          end

          timer("Cache update") do
            SimpleMaster.use_dataset(self) do
              self.class.run_after_load
            end
          end
        end
        self
      end

      def unload
        cache.clear
        tables.clear
      end

      # Note: Pass a empty hash to duplicate with empty diff.
      def duplicate(diff: nil)
        diff ||= @diff
        new_dataset = self.class.new(table_class: table_class, loader: loader)
        new_dataset.diff = diff.deep_dup
        tables.each do |klass, table|
          new_dataset.tables[klass] = table.duplicate_for(new_dataset)
        end

        new_dataset
      end

      def reload_klass(klass)
        fail NotImplementedError unless table_class == SimpleMaster::Storage::OndemandTable

        tables.delete(klass)
      end
      alias reload_class reload_klass

      # Cache helper for other data sources.
      def cache_read(key)
        cache[key]
      end

      def cache_fetch(key)
        cache.fetch(key) do
          cache[key] = yield
        end
      end

      def cache_write(key, value)
        cache[key] = value
      end

      def cache_delete(key)
        cache.delete(key)
      end

      # NOTE: set diff before records loaded.
      def diff=(diff_json)
        @diff = if diff_json.is_a?(String)
                  JSON.parse(diff_json)
                else
                  diff_json || {}
                end
      end

      private

      def memsize
        GC.compact
        before = ObjectSpace.memsize_of_all

        res = yield

        GC.compact
        after = ObjectSpace.memsize_of_all

        SimpleMaster.logger.info { "Consumed memory size: #{after - before}" }

        res
      end

      def timer(text)
        t1 = Time.zone.now
        @timer_index ||= 0
        @timer_index += 1

        res = yield

        t2 = Time.zone.now
        @timer_index -= 1

        SimpleMaster.logger.info { "#{'  ' * @timer_index}#{text}: #{t2 - t1}s" }

        res
      end
    end
  end
end
