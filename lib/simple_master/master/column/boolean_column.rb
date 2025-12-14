# frozen_string_literal: true

module SimpleMaster
  class Master
    class Column
      class BooleanColumn < self
        def init(master_class, for_test = false)
          super

          master_class.simple_master_module.class_eval <<-RUBY, __FILE__, __LINE__ + 1
            def #{name}?
              !!#{name}
            end
          RUBY
        end

        private

        def code_for_conversion
          <<-RUBY
            value = cache_object(:#{name}, value) { |value|
              if value.is_a?(Integer)
                value != 0
              elsif value.is_a?(String)
                value.downcase == "true" || value == "1"
              elsif value.nil?
                value
              else
                !!value
              end
            }
          RUBY
        end

        def code_for_sql_value
          <<-RUBY
            # true, falseに対応しない場合があるので、0, 1に変換する
            case #{name}
            when true
              1
            when false
              0
            else
              nil
            end
          RUBY
        end
      end
    end
  end
end
