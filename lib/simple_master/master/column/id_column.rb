# frozen_string_literal: true

module SimpleMaster
  class Master
    class Column
      class IdColumn < self
        private

        def code_for_conversion
          <<-RUBY
            value = value&.to_i
          RUBY
        end

        def code_for_dirty_check
          <<-RUBY
            unless @#{name} == value
              dirty!
              # IDs require updating @id_hash when changed
              self.class.id_hash.delete(@#{name}) if @#{name}
            end
          RUBY
        end

        def globalize
          fail NotImplementedError
        end
      end
    end
  end
end
