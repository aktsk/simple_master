# frozen_string_literal: true

module SimpleMaster
  class Loader
    class MarshalLoader < Loader
      def read_raw(table)
        path = "#{@options[:path]}/#{table.klass.table_name}.marshal"
        return nil unless File.exist?(path)

        File.read(path)
      end

      def build_records(_klass, raw)
        return [] if raw.nil?

        Marshal.load(raw) # rubocop:disable Security/MarshalLoad
      end
    end
  end
end
