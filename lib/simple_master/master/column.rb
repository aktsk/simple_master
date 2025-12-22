# frozen_string_literal: true

module SimpleMaster
  class Master
    class Column
      attr_reader :name
      attr_reader :options
      attr_accessor :group_key

      def self.column_type
        klass_name = name.split("::").last
        type_name = klass_name.delete_suffix('Column')
        return :column if type_name.empty?

        type_name.underscore.to_sym
      end

      def self.inherited(subclass)
        type = subclass.column_type
        Column.register(type, subclass)
      end

      def self.column_types
        @column_types ||= {}
      end

      def self.register(type, klass)
        if column_types.key?(type)
          fail "#{klass}: Column type #{type} is defined at #{column_types[type]}."
        end

        column_types[type] = klass
      end

      register(:column, self)

      def initialize(name, options)
        @name = name
        @group_key = !!options[:group_key]
        @options = options
      end

      def init(master_class, for_test = false)
        master_class.simple_master_module.attr_reader name

        master_class.simple_master_module.class_eval <<-RUBY, __FILE__, __LINE__ + 1
          def #{name}=(value)
            #{code_for_conversion}
            #{code_for_dirty_check if for_test}
            @#{name} = value
          end

          def #{name}_value_for_sql
            value = #{code_for_sql_value}
            return "NULL" if value.nil?
            return "'" + value.gsub(/'/, "''").gsub("\\\\", '\\&\\&') + "'" if value.is_a?(String)
            value
          end

          # For inspecting raw DB/CSV values when checking CSV diffs
          def #{name}_value_for_csv
            #{code_for_sql_value}
          end
        RUBY

        globalize(master_class) if options[:globalize]

        if options[:db_column_name]
          master_class.simple_master_module.alias_method :"#{options[:db_column_name]}=", :"#{name}="
        end
      end

      def db_column_name
        options[:db_column_name] || name
      end

      private

      def code_for_conversion
      end

      def globalize(master_class)
        fail "#{master_class}.#{name}: group key can not be globalized." if options[:group_key]

        mod = Module.new
        mod.class_eval <<-RUBY, __FILE__, __LINE__ + 1
          def #{name}
            return super if @_globalized_#{name}.nil?
            @_globalized_#{name}.fetch(I18n.locale) { super }
          end

          attr_reader :_globalized_#{name}

          def _globalized_#{name}=(hash_or_json)
            hash = hash_or_json.is_a?(String) ? JSON.parse(hash_or_json, symbolize_names: true) : hash_or_json
            @_globalized_#{name} = hash&.transform_values { |value|
              #{code_for_conversion}
              value
            }
          end

          def _globalized_#{name}_set(locale, value)
            @_globalized_#{name} ||= {}
            #{code_for_conversion}
            @_globalized_#{name}[locale] = value
          end
        RUBY

        master_class.simple_master_module.prepend(mod)
      end

      def code_for_dirty_check
        <<-RUBY
          dirty! unless @#{name} == value
        RUBY
      end

      def code_for_sql_value
        <<-RUBY
          self.#{name}
        RUBY
      end
    end
  end
end

require "simple_master/master/column/id_column"
require "simple_master/master/column/integer_column"
require "simple_master/master/column/float_column"
require "simple_master/master/column/string_column"
require "simple_master/master/column/symbol_column"
require "simple_master/master/column/boolean_column"
require "simple_master/master/column/json_column"
require "simple_master/master/column/time_column"
require "simple_master/master/column/enum_column"
require "simple_master/master/column/bitmask_column"
require "simple_master/master/column/sti_type_column"
require "simple_master/master/column/polymorphic_type_column"
