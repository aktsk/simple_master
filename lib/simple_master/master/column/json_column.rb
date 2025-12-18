# frozen_string_literal: true

module SimpleMaster
  class Master
    class Column
      class JsonColumn < self
        private

        def code_for_conversion
          <<-RUBY
            value = cache_object(:#{name}, value) { |value|
              value = JSON.parse(value, symbolize_names: #{!!options[:symbolize_names]}) if value.is_a?(String)
              value
            }
          RUBY
        end

        def code_for_sql_value
          <<-RUBY
            # Use JSON.generate because to_json adds unnecessary escaping
            #{name}&.then { JSON.generate(_1) }
          RUBY
        end
      end
    end
  end
end
