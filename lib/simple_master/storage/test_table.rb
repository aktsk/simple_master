# frozen_string_literal: true

require "simple_master/storage/table"

module SimpleMaster
  module Storage
    # Ondemand table based on updated id_hash.
    class TestTable < Table
      def initialize(_klass, _dataset, _loader)
        super

        @all = []
        @id_hash = {}
        @grouped_hash = {}
        @class_method_cache = {}
        @method_cache = Hash.new { |k, v| k[v] = {}.compare_by_identity }.compare_by_identity

        @all_need_update = true
        @grouped_hash_need_update = true
        @class_method_cache_need_update = true
      end

      def sub_table(sub_klass)
        (@sub_tables ||= klass.descendants.reject(&:abstract_class).index_with { |k| self.class.new(k, dataset, loader) })[sub_klass]
      end

      def update(id, record)
        id_hash[id] = record
        @all_need_update = true
        @grouped_hash_need_update = true
        @class_method_cache_need_update = true
      end

      def record_updated
        @grouped_hash_need_update = true
        @class_method_cache_need_update = true
      end

      def all=(records)
        @all_need_update = false
        super.tap { update_id_hash }
      end

      def all
        if @all_need_update
          @all_need_update = false
          @all = id_hash.values
        end
        @all
      end

      def grouped_hash
        if @grouped_hash_need_update
          @grouped_hash_need_update = false
          update_grouped_hash
        end
        @grouped_hash
      end

      def class_method_cache
        if @class_method_cache_need_update
          @class_method_cache_need_update = false
          update_class_method_cache
        end
        @class_method_cache
      end
    end
  end
end
