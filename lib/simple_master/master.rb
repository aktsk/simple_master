# frozen_string_literal: true

module SimpleMaster
  class Master
    autoload :Column, "simple_master/master/column"
    autoload :Association, "simple_master/master/association"
    autoload :Editable, "simple_master/master/editable"
    autoload :Dsl, "simple_master/master/dsl"
    autoload :Filterable, "simple_master/master/filterable"
    autoload :Storable, "simple_master/master/storable"
    autoload :Queryable, "simple_master/master/queryable"
    autoload :Validatable, "simple_master/master/validatable"

    extend Dsl
    extend Filterable
    extend Storable
    extend Queryable
    include Validatable

    class << self
      attr_accessor :abstract_class

      #: () -> bool
      def abstract_class?
        !!abstract_class
      end

      #: () -> bool
      def table_exists?
        table_available?
      end

      # 自動作成のメソッドを module に入れることで、overrideできるようにしています。
      def simple_master_module
        @simple_master_module ||= Module.new
      end

      # def simple_master_class_methods
      #   @simple_master_class_methods ||= Module.new
      # end

      #: () -> Array[Integer]
      def ids
        id_hash.keys
      end

      #: () -> Array[SimpleMaster::Master::Column]
      def columns
        @columns ||= []
      end

      #: () -> Array[SimpleMaster::Master::Column]
      def all_columns
        if superclass < SimpleMaster::Master
          (superclass.all_columns + columns).reverse.uniq(&:name).reverse
        else
          columns
        end
      end

      def update_column_info(name)
        if (column_index = columns.find_index { _1.name == name })
          columns[column_index] = yield(columns[column_index])
          return
        end

        if (column_from_parent = superclass.all_columns.find { _1.name == name })
          new_column = yield(column_from_parent)
          columns << new_column
          return
        end

        fail "Column #{name} not found on #{self}!"
      end

      #: () -> Array[String]
      def column_names
        all_columns.map(&:name)
      end

      # ARの仕様と違い、カラムの存在を確認できるようにしただけ。
      #: () -> Hash[String, SimpleMaster::Master::Column]
      def columns_hash
        all_columns.index_by(&:name).with_indifferent_access
      end

      def has_one_associations
        @has_one_associations ||= []
      end

      def all_has_one_associations
        if superclass < SimpleMaster::Master
          superclass.all_has_one_associations + has_one_associations
        else
          has_one_associations
        end
      end

      def has_many_associations
        @has_many_associations ||= []
      end

      def all_has_many_associations
        if superclass < SimpleMaster::Master
          superclass.all_has_many_associations + has_many_associations
        else
          has_many_associations
        end
      end

      def belongs_to_associations
        @belongs_to_associations ||= []
      end

      def all_belongs_to_associations
        if superclass < SimpleMaster::Master
          superclass.all_belongs_to_associations + belongs_to_associations
        else
          belongs_to_associations
        end
      end

      def group_keys
        @group_keys || all_columns.select(&:group_key).map(&:name)
      end

      def sti_base_class
        nil
      end

      def sti_column
        nil
      end

      # @rbs skip
      alias inheritance_column sti_column

      def primary_key
        :id
      end

      # @rbs skip
      alias polymorphic_name name

      def has_query_constraints?
        false
      end

      def composite_primary_key?
        false
      end

      def table_name
        ActiveSupport::Inflector.tableize(base_class.to_s).tr("/", "_")
      end

      def current_scope
        fail
        # pp caller
        # raise
        # @current_scope ||= Scope.new
      end

      #: () -> void
      def init(database_available = true, for_test: false)
        @object_cache = Hash.new { |k, v| k[v] = {} }

        _build_dsl
        _build_columns(for_test)
        _build_associations(database_available, for_test)
        _build_sti_methods

        # Override on test env.
        define_method(:cache_object) { |_column, input, &block| block.call(input) } if for_test
      end

      #: () -> void
      def dsl_initializers
        @dsl_initializers ||= []
      end

      #: () -> void
      def _build_dsl
        dsl_initializers.each(&:call)
      end

      #: () -> void
      def _build_columns(for_test)
        columns.each do |column|
          column.init(self, for_test)
        end

        @group_keys = group_keys

        simple_master_module.class_eval <<-RUBY, __FILE__, __LINE__ + 1
          def attributes
            {
              #{
                all_columns.map { |column| "#{column.name}: #{column.name}" }.join(",\n")
              }
            }
          end

          def db_attributes
            {
              #{
                all_columns.map { |column| "#{column.db_column_name}: #{column.name}_value_for_csv" }.join(",\n")
              }
            }
          end

          def globalized_db_attributes
            {
              #{
                all_columns.map { |column| "#{column.db_column_name}: #{column.name}_value_for_csv" }.join(",\n")
              },
              #{
                all_columns.select { |column| column.options[:globalize] }.map { |column|
                  "_globalized_#{column.name}: _globalized_#{column.name}"
                }.join(",\n")
              }
            }
          end

          def create_copy
            r = self.class.default_object.dup
            #{
              all_columns.map { |column| "r.#{column.name} = #{column.name}" }.join("\n")
            }
            r
          end
        RUBY

        build_default_object
      end

      #: () -> void
      def _build_associations(is_database_available, for_test)
        associations = has_one_associations + has_many_associations + belongs_to_associations

        associations.each do |association|
          next if !is_database_available && association.is_active_record?
          association.init(self)
          association.init_for_test(self) if for_test
        end
      end

      def _build_sti_methods
        extend SubClassStorable if sti_sub_class?
      end

      def inherited(subclass)
        super
        subclass.include(subclass.simple_master_module)
      end

      attr_reader :class_method_cache_info #: Array[[Symbol, Proc]]
      attr_reader :instance_methods_need_tap #: Array[Symbol]
      attr_reader :default_object #: self
      attr_reader :object_cache #: Hash[Symbol, untyped]

      # @rbs return: Array[[Symbol, Proc]]
      def all_class_method_cache_info
        if superclass < SimpleMaster::Master
          superclass.all_class_method_cache_info + (class_method_cache_info || EMPTY_ARRAY)
        else
          class_method_cache_info || EMPTY_ARRAY
        end
      end

      def scope(*_option)
      end

      def sti_class?
        !!sti_base_class
      end

      def sti_base_class?
        sti_base_class == self
      end

      def sti_sub_class?
        !!sti_base_class && sti_base_class != self
      end

      def base_class
        sti_base_class || self
      end

      def base_class?
        !sti_base_class || sti_base_class?
      end

      def globalized?
        all_columns.any? { |column| column.options[:globalize] }
      end

      #: () -> void
      def reset_object_cache
        @object_cache.clear
      end

      #: () -> void
      def build_default_object
        default_object = allocate

        all_columns.each do |column|
          # 高速化のため、定義されていない場合でも nil を代入する
          default_object.send :"#{column.name}=", column.options[:default].freeze
          default_object.send :"_globalized_#{column.name}=", nil if column.options[:globalize]
        end
        default_object.type = name if sti_class?

        @default_object = default_object
      end
    end

    #: (Symbol, untyped) { (untyped) -> untyped } -> untyped
    def cache_object(column, input)
      cache = self.class.base_class.object_cache[column]
      cache.fetch(input) { cache[input] = yield(input) }
    end

    def instance_store
      store = RequestStore.store
      instance_store = store.fetch(:instance_store) { store[:instance_store] = Hash.new { |hash, key| hash[key] = {} }.compare_by_identity }
      instance_store[self]
    end

    def has_many_store
      RequestStore.store[:has_many_store] ||= {}.compare_by_identity
      RequestStore.store[:has_many_store][self] ||= {}
    end

    def belongs_to_store
      RequestStore.store[:belongs_to_store] ||= {}.compare_by_identity
      RequestStore.store[:belongs_to_store][self] ||= {}
    end

    def dirty!
    end

    alias [] send

    def _read_attribute(key)
      instance_variable_get("@#{key}")
    end

    alias read_attribute _read_attribute

    def slice(*attrs)
      attrs.index_with { send(_1) }
    end

    def as_json(_option = nil)
      attributes
    end

    # for comparing in test.
    def json_slice(*attrs)
      JSON.parse(slice(*attrs).to_json)
    end

    #: () -> bool
    def destroyed?
      false
    end

    #: () -> bool
    def new_record?
      false
    end

    #: () -> bool
    def has_changes_to_save?
      false
    end

    #: () -> bool
    def marked_for_destruction?
      false
    end

    def save(*_)
    end

    def save!(*_)
    end

    def update(*_)
    end

    def update!(*_)
    end

    def destroy
    end

    def destroy!
    end

    def inspect
      "#<#{self.class.name}:#{'%#016x' % (object_id << 1)} #{attributes.inspect}>"
    end

    def initialize(attributes = nil)
      attributes&.each do |key, value|
        send :"#{key}=", value
      end
      yield self if block_given?
    end

    def self.new(attributes = nil, &)
      default_object.dup.tap { _1.send(:initialize, attributes, &) }
    end
  end
end
