# frozen_string_literal: true

module SimpleMaster
  class Master
    class Column
      class BitmaskColumn < self
        attr_reader :name
        attr_reader :bitmask
        attr_reader :const_name

        def initialize(name, options)
          @bitmask = options[:bitmask]
          @const_name = "BITMASK_FOR_#{name.upcase}"

          super
        end

        def init(master_class, for_test = false)
          super

          master_class.simple_master_module.const_set(const_name, bitmask) unless master_class.const_defined?(const_name)

          master_class.simple_master_module.class_eval <<-RUBY, __FILE__, __LINE__ + 1
            def #{name}
              return EMPTY_ARRAY if @#{name}.nil?
              #{const_name}.filter_map.with_index {
                _1 if (1 << _2) & @#{name} != 0
              }
            end

            def #{name}_value
              @#{name}
            end

            def #{name}_value=(value)
              #{code_for_dirty_check if for_test}
              @#{name} = value&.to_i
            end
          RUBY
        end

        private

        def code_for_conversion
          <<-RUBY
            value = cache_object(:#{name}, value) { |value|
              value = [value] if value.is_a?(Symbol)

              if value.is_a?(Array)
                bits = 0
                value.each do |day|
                  bits |= 1 << #{const_name}.index(day)
                end
                bits
              else
                value&.to_i
              end
            }
          RUBY
        end

        def code_for_sql_value
          <<-RUBY
            @#{name}
          RUBY
        end

        def globalize
          fail NotImplementedError
        end
      end
    end
  end
end
