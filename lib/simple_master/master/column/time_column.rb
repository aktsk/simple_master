# frozen_string_literal: true

module SimpleMaster
  class Master
    class Column
      class TimeColumn < self
        private

        def code_for_conversion
          <<-RUBY
            value = cache_object(:#{name}, value) { |value|
              if value.is_a?(String)
                #{"value = value.sub(/\A\d{4}-\d\d-\d\d(?:T|\s)|/, \"2000-01-01 \")" if options[:db_type] == :time}
                time_hash = ::Date._parse(value)
                zone = time_hash[:offset] || "UTC"
                value = Time.new(*time_hash.values_at(:year, :mon, :mday, :hour, :min, :sec), zone)
              end
              value = value.floor if value && value.subsec != 0
              value
            }
          RUBY
        end

        def code_for_sql_value
          if options[:db_type] == :time
            <<-RUBY
              #{name}&.getutc&.strftime('%H:%M:%S')
            RUBY
          else
            <<-RUBY
              #{name}&.getutc&.strftime('%Y-%m-%d %H:%M:%S')
            RUBY
          end
        end
      end
    end
  end
end
