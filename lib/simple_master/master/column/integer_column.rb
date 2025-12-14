# frozen_string_literal: true

module SimpleMaster
  class Master
    class Column
      class IntegerColumn < self
        private

        def code_for_conversion
          <<-RUBY
            if value.is_a?(String) && value.strip.empty?
              value = nil
            else
              value = value&.to_i
            end
          RUBY
        end
      end
    end
  end
end
