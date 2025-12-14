# frozen_string_literal: true

module SimpleMaster
  class Master
    class Column
      class PolymorphicTypeColumn < self
        def init(master_class, for_test = false)
          super

          master_class.simple_master_module.attr_reader :"#{name}_class"
          master_class.simple_master_module.attr_reader name

          master_class.simple_master_module.class_eval <<-RUBY, __FILE__, __LINE__ + 1
            def #{name}=(value)
              #{code_for_conversion}
              #{code_for_dirty_check if for_test}
              @#{name} = value
              @#{name}_class = value&.then { ActiveSupport::Inflector.constantize(_1) }
            end

            def #{name}_class=(klass)
              #{"dirty! unless @#{name}_class == klass" if for_test}
              @#{name} = klass.to_s
              @#{name}_class = klass
            end
          RUBY
        end

        private

        def code_for_conversion
          <<-RUBY
            value = nil if value == ""
            value = cache_object(:#{name}, value) { _1&.to_s }
          RUBY
        end

        def globalize
          fail NotImplementedError
        end
      end
    end
  end
end
