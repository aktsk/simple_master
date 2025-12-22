# frozen_string_literal: true

module SimpleMaster
  class Master
    class Column
      class EnumColumn < self
        attr_reader :name
        attr_reader :enum
        attr_reader :const_name
        attr_reader :prefix
        attr_reader :suffix

        def initialize(name, options)
          @enum = options[:enum]
          @const_name = "ENUM_FOR_#{name.upcase}"
          @prefix = "#{name}_" if options[:prefix]
          @suffix = "_#{options[:suffix]}" if options[:suffix]

          super
        end

        def init(master_class, for_test = false)
          super

          master_class.simple_master_module.const_set(const_name, enum.freeze) unless master_class.const_defined?(const_name)

          master_class.class_eval <<-RUBY, __FILE__, __LINE__ + 1
            def self.#{name.to_s.pluralize}
              #{const_name}
            end
          RUBY

          master_class.simple_master_module.class_eval <<-RUBY, __FILE__, __LINE__ + 1
            def #{name}_to_enum(value)
              case value
              when Integer
                return #{const_name}.key(value)
              when String
                sym = value.to_sym
                return sym if #{const_name}.key?(sym)

                int_val = Integer(value, exception: false)
                if int_val
                  result = #{const_name}.key(int_val)
                  return result if result
                end

                fail "Unsupported type \#{value.inspect}."
              when Symbol, NilClass
                return value
              else
                fail "Unsupported type \#{value.inspect}."
              end
            end

            def #{name.to_s.pluralize}
              #{const_name}
            end

            def #{name}_before_type_cast
              #{const_name}[#{name}]
            end
          RUBY

          enum.each_key do |enum_name|
            # Skip generating helpers for names that start with a digit
            next if enum_name.match?(/\A\d/)
            master_class.simple_master_module.class_eval <<-RUBY, __FILE__, __LINE__ + 1
                def #{prefix}#{enum_name}#{suffix}?
                  #{name} == :#{enum_name}
                end
            RUBY
          end
        end

        private

        def code_for_conversion
          <<-RUBY
            value = cache_object(:#{name}, value) { #{name}_to_enum(_1) }
          RUBY
        end

        def code_for_sql_value
          <<-RUBY
            #{name}_before_type_cast
          RUBY
        end

        def globalize
          fail NotImplementedError
        end
      end
    end
  end
end
