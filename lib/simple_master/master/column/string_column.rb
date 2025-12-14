# frozen_string_literal: true

module SimpleMaster
  class Master
    class Column
      class StringColumn < self
        private

        def code_for_conversion
          <<-RUBY
            value = cache_object(:#{name}, value) { _1&.to_s }
          RUBY
        end
      end
    end
  end
end
