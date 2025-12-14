# frozen_string_literal: true

require "simple_master/storage/table"

module SimpleMaster
  module Storage
    class OndemandTable < Table
      def sub_table(sub_klass)
        (@sub_tables ||= klass.descendants.reject(&:abstract_class).index_with { |k| self.class.new(k, dataset, loader) })[sub_klass]
      end

      def load_records
        @class_method_cache = nil
        super
      end

      def all
        return @all if @all

        if klass.sti_sub_class?
          klass.sti_base_class.all
          @all
        else
          load_records
          SimpleMaster.use_dataset(dataset) do
            tap_instance_methods
            freeze_all
          end
        end
      end

      def id_hash
        return @id_hash if @id_hash

        update_id_hash
      end

      def grouped_hash
        return @grouped_hash if @grouped_hash

        update_grouped_hash
      end

      def class_method_cache
        return @class_method_cache if @class_method_cache

        # make sure @all is loaded to prevent errors
        all

        update_class_method_cache
      end

      def update_sub_tables
        sub_klasses = klass.descendants.reject(&:abstract_class)
        return if sub_klasses.empty?

        grouped = all.group_by(&:class)
        sub_klasses.each do |sub_klass|
          sub_sub_klasses = [sub_klass, *sub_klass.descendants].reject(&:abstract_class)

          sub_table = self.sub_table(sub_klass)
          sub_table.all = sub_sub_klasses.flat_map { grouped[_1] || EMPTY_ARRAY }.freeze
          sub_table.digest = digest
        end
      end
    end
  end
end
