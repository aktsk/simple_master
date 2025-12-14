# frozen_string_literal: true

module SimpleMaster
  class Master
    class Column
      class StiTypeColumn < self
        private

        def code_for_conversion
          <<-RUBY
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
