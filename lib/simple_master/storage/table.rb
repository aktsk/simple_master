# frozen_string_literal: true

module SimpleMaster
  module Storage
    class Table
      METADATA_PREFIX = "__"

      def initialize(klass, dataset, loader)
        @klass = klass
        @dataset = dataset
        @loader = loader
        @method_cache = Hash.new { |k, v| k[v] = {}.compare_by_identity }.compare_by_identity

        @sub_tables = nil
      end

      def sub_table(klass)
        @sub_tables[klass]
      end

      def duplicate_for(dataset, table_klass = self.class)
        table = table_klass.new(klass, dataset, loader)

        if table.diff == applied_diff
          table.all = all
          table.applied_diff = applied_diff
          table.digest = digest

          # ロードされている場合、既存id_hash, grouped_hashをコピー
          table.id_hash = id_hash if @id_hash
          table.grouped_hash = grouped_hash if @grouped_hash
          table.sub_tables = sub_tables&.transform_values { |sub_table|
            sub_table.duplicate_for(dataset)
          }
        end

        table
      end

      def load_records
        @method_cache.clear

        loader.load_records(self)
      end

      attr_accessor :klass
      attr_accessor :dataset
      attr_accessor :loader
      attr_accessor :sub_tables
      attr_accessor :all
      attr_accessor :id_hash
      attr_accessor :grouped_hash
      attr_accessor :class_method_cache
      attr_accessor :method_cache
      attr_accessor :applied_diff
      attr_accessor :digest

      def freeze_all
        all.each(&:freeze).tap { run_on_sub_tables(:freeze_all) }
      end

      def update_id_hash
        self.id_hash = all.index_by(&:id).freeze
      end

      def update_grouped_hash
        grouped_hash = {}.compare_by_identity

        klass.group_keys.each do |group_key|
          grouped_hash[group_key] = all.group_by(&group_key).freeze.each_value(&:freeze)
        end
        grouped_hash.freeze

        self.grouped_hash = grouped_hash
      end

      def update_class_method_cache
        self.class_method_cache = class_method_cache = {}.compare_by_identity
        # blockだと宣言したクラスのコンテキストになるため、instance_eval を利用する
        klass.all_class_method_cache_info.each do |args, initializer|
          result = klass.instance_eval(&initializer)
          if args.length == 1
            result = [result]
          end

          args.zip(result).each do |arg, value|
            class_method_cache[arg] = value
          end
        end
        class_method_cache.freeze.tap {
          run_on_sub_tables(:update_class_method_cache)
        }
      end

      def tap_instance_methods
        klass.instance_methods_need_tap&.each do |method_name|
          all.each(&method_name)
        end
        run_on_sub_tables(:tap_instance_methods)
      end

      def update_sub_tables
        sub_klasses = klass.descendants.reject(&:abstract_class)
        return if sub_klasses.empty?

        @sub_tables = sub_klasses.index_with { |sub_klass| self.class.new(sub_klass, dataset, loader) }

        grouped = all.group_by(&:class)

        sub_klasses.each do |sub_klass|
          sub_sub_klasses = [sub_klass, *sub_klass.descendants].reject(&:abstract_class)

          sub_table = self.sub_table(sub_klass)
          sub_table.all = sub_sub_klasses.flat_map { grouped[_1] || EMPTY_ARRAY }.freeze
          sub_table.digest = digest
          sub_table.applied_diff = applied_diff
          sub_table.update_id_hash
          sub_table.update_grouped_hash
        end
      end

      def run_on_sub_tables(method)
        sub_tables&.each_value(&method)
      end

      def diff
        dataset.diff[klass.table_name]
      end

      def apply_diff
        update_id_hash
        if diff.present?
          apply_diff_to_id_hash
          self.all = id_hash.values.freeze
        end
        update_grouped_hash

        self
      end

      def apply_diff_to_id_hash
        id_hash = self.id_hash.dup
        diff&.each do |key, record_diff|
          next if metadata_key?(key)
          id = key.to_i

          if record_diff.nil?
            id_hash.delete(id)
            next
          end

          original_record = id_hash[id]

          record =
            if original_record.nil?
              new_klass = klass.sti_column && record_diff[klass.sti_column.to_s]&.constantize || klass
              new_klass.new(id: id)
            elsif klass.sti_column && record_diff[klass.sti_column.to_s]
              record_diff[klass.sti_column.to_s].constantize.new(original_record.attributes)
            else
              original_record.create_copy
            end

          record_diff.each do |k, v|
            next if metadata_key?(k)
            # jsonカラムでjsonが展開状態のケースも考慮（キーがstringとなってしまうため、jsonに戻してから代入）
            if v.is_a?(Hash) || v.is_a?(Array)
              v = v.to_json
            end
            record.send(:"#{k}=", v)
          rescue NoMethodError => _e
            raise ColumnNotExist, "カラム #{k} が #{klass} に存在しません."
          rescue => e
            raise AssignmentError, "データの代入に失敗: #{klass}.#{k} = #{v.inspect}. Message: #{e.message}."
          end

          id_hash[id] = record
        end

        self.applied_diff = diff
        self.id_hash = id_hash.freeze
      end

      class ColumnNotExist < StandardError
      end

      class AssignmentError < StandardError
      end

      private

      def metadata_key?(key)
        key.to_s.start_with?(METADATA_PREFIX)
      end
    end
  end
end
