# frozen_string_literal: true

module SimpleMaster
  class Master
    # クラス定義をするときに書くものはここのモジュールに集約される
    module Dsl
      TYPES_BY_OPTIONS = {
        polymorphic_type: Column::PolymorphicTypeColumn,
        sti: Column::StiTypeColumn,
        enum: Column::EnumColumn,
        bitmask: Column::BitmaskColumn,
      }.freeze

      def def_column(column_name, options = EMPTY_HASH)
        column = column_type(column_name, options).new(column_name, options)
        columns << column

        if options[:sti]
          class_eval <<-RUBY, __FILE__, __LINE__ + 1
            def self.sti_base_class
              #{name}
            end

            def self.sti_column
              :#{column_name}
            end
          RUBY
        end
      end

      def has_one(name, options = EMPTY_HASH)
        ass = Association::HasOneAssociation.new(self, name, options)
        has_one_associations << ass
      end

      def has_many(name, options = {})
        ass =
          if options[:through]
            Association::HasManyThroughAssociation.new(self, name, options)
          else
            Association::HasManyAssociation.new(self, name, options)
          end

        has_many_associations << ass
      end

      def belongs_to(name, options = EMPTY_HASH)
        ass =
          if options[:polymorphic]
            Association::BelongsToPolymorphicAssociation.new(self, name, options)
          else
            Association::BelongsToAssociation.new(self, name, options)
          end

        belongs_to_associations << ass
      end

      def group_key(column_name)
        proc {
          update_column_info(column_name) do |column|
            column.group_key = true

            column
          end
        }.tap { dsl_initializers << _1 }
      end

      def enum(*args)
        if args.length == 1
          options = args.first
          proc {
            options.each do |name, enums|
              update_column_info(name) do |column|
                Column::EnumColumn.new(name, column.options.merge(enum: enums))
              end
            end
          }.tap { dsl_initializers << _1 }
        elsif args.length >= 2
          name = args.shift
          enums = args.shift
          options = args.shift || {}

          proc {
            update_column_info(name) do |column|
              Column::EnumColumn.new(name, column.options.merge(options.merge(enum: enums)))
            end
          }.tap { dsl_initializers << _1 }
        else
          fail
        end
      end

      def bitmask(name, options = Association)
        proc {
          update_column_info(name) do |column|
            Column::BitmaskColumn.new(name, column.options.merge(bitmask: options[:as]))
          end
        }.tap { dsl_initializers << _1 }
      end

      def globalize(column_name)
        proc {
          update_column_info(column_name) do |column|
            column.options[:globalize] = true
            column
          end
        }.tap { dsl_initializers << _1 }
      end

      # * ロード時に生成され、datasetに保存されるキャッシュ。
      #
      #     cache_class_method method_name_symbol
      #
      # * defの戻り値を利用すると、下記のようにも宣言可能
      #
      #     cache_class_method def self.method_name
      #       ...
      #     end
      #
      # * ブロックを渡す場合、既存メソッドではなく、ブロックでキャッシュ生成する。
      #
      #     cache_class_method method_name_symbol { ... }
      #
      # * クラスメソッドが生成され、複数の引数を渡すことでまとめて生成することが可能。
      #
      #     cache_class_method(:cache1, :cache2) {
      #       ...
      #       [cache1, cache2]
      #     }
      def cache_class_method(*args, &block)
        @class_method_cache_info ||= []
        if block_given?
          @class_method_cache_info << [args, block]
        else
          args.each do |arg|
            method_name = :"_class_cache_#{arg}"
            @class_method_cache_info << [[arg], method_name]
            singleton_class.alias_method method_name, arg
          end
        end

        args.each do |arg|
          define_singleton_method(arg) do
            class_method_cache[arg]
          end
        end
      end

      alias def_custom_cache cache_class_method

      # レコードのロード後に一度メソッドをアクセスする
      def tap_instance_method(method_name)
        @instance_methods_need_tap ||= []
        @instance_methods_need_tap << method_name
      end

      # * ロード時に生成され、インスタンス変数に保存されるキャッシュ。
      #   挙動は軽いが、datasetを参照してはいけないので利用時に注意が必要。
      #   基本的にレコードのattributeで生成するキャッシュとして利用する。
      #
      #     cache_attribute method_name_symbol
      #
      # * defの戻り値を利用すると、下記のようにも宣言可能
      #
      #     cache_attribute def method_name
      #       ...
      #     end
      #
      # * ブロックを渡すと、ブロックでキャッシュ生成する。
      # cache_attribute method_name { ... }
      def cache_attribute(method_name, &)
        calc_method_name = :"_attribute_cache_#{method_name}"

        if block_given?
          define_method(calc_method_name, &)
        else
          alias_method calc_method_name, method_name
        end

        class_eval <<-RUBY, __FILE__, __LINE__ + 1
          def #{method_name}
            return @#{method_name} if defined? @#{method_name}

            @#{method_name} = #{calc_method_name}
          end
        RUBY

        tap_instance_method method_name
      end

      # * ロード時に生成され、datasetに保存されるキャッシュ。
      #   datasetを利用するので、cache_attributeより挙動が重い。
      #
      #     cache_method method_name_symbol
      #
      # * defの戻り値を利用すると、下記のようにも宣言可能
      #
      #     cache_method def method_name
      #       ...
      #     end
      #
      # * ブロックを渡すと、ブロックでキャッシュ生成する。
      #
      #     cache_method method_name_symbol { ... }
      def cache_method(method_name, &)
        calc_method_name = :"_method_cache_#{method_name}"
        if block_given?
          define_method(calc_method_name, &)
        else
          alias_method calc_method_name, method_name
        end

        class_eval <<-RUBY, __FILE__, __LINE__ + 1
          def #{method_name}
            self.class.method_cache[:#{method_name}].fetch(self) {
              self.class.method_cache[:#{method_name}][self] = #{calc_method_name}
            }
          end
        RUBY

        tap_instance_method method_name
      end

      private

      def column_type(column_name, options)
        return Column::IdColumn if column_name == :id

        TYPES_BY_OPTIONS.each do |option_key, type|
          return type if options[option_key]
        end

        return Column unless options[:type]

        Column.column_types.fetch(options[:type]) { fail "Undefined column type: #{options[:type]}" }
      end
    end
  end
end
