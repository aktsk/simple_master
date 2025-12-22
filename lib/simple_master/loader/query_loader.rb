# frozen_string_literal: true

module SimpleMaster
  class Loader
    class QueryLoader < Loader
      def read_raw(table)
        klass = table.klass
        unless klass.table_available?
          return { columns: EMPTY_ARRAY, rows: EMPTY_ARRAY }
        end

        result = klass.query_select_all

        { columns: result.columns, rows: result.rows }
      end

      def build_records(klass, raw)
        columns = raw[:columns].map(&:to_sym)

        column_assign_methods = columns.map { :"#{_1}=" }
        columns_hash = klass.columns_hash
        sti_column_index = columns.find_index { columns_hash[_1].is_a?(Master::Column::StiTypeColumn) }

        columns.each do |column_name|
          unless klass.method_defined?(:"#{column_name}=")
            if ENV["RAILS_ENV"] == "development"
              # In local/dev, define a no-op setter so loading does not raise
              klass.define_method(:"#{column_name}=", &:itself)
              warn "#{klass}.#{column_name} column is not defined!"
            else
              fail "#{klass}.#{column_name} column is not defined!"
            end
          end
        end

        raw[:rows].filter_map { |row|
          begin
            record =
              if sti_column_index
                child_klass = ActiveSupport::Inflector.constantize(row[sti_column_index])
                if child_klass == klass || child_klass.sti_base_class == klass
                  child_klass.new
                else
                  warn "[#{klass}] Invalid value in the type column: #{row}"
                  next
                end
              else
                klass.new
              end

            column_assign_methods.zip(row) do |assign_method, value|
              record.send(assign_method, value)
            end

            record
          rescue
            nil
          end
        }.freeze
      end
    end
  end
end
