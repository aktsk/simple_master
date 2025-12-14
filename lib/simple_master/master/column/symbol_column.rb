# frozen_string_literal: true

module SimpleMaster
  class Master
    class Column
      class SymbolColumn < self
        private

        def code_for_conversion
          <<-RUBY
            value = value&.to_s&.to_sym
          RUBY
        end

        def code_for_sql_value
          <<-RUBY
            #{name}&.to_s
          RUBY
        end
      end
    end
  end
end
