# frozen_string_literal: true

module SimpleMaster
  class Loader
    class MarshalLoader < Loader
      def read_raw(table)
        File.read("#{@options[:path]}/#{table.klass.table_name}.marshal")
      end

      def build_records(_klass, raw)
        Marshal.load(raw) # rubocop:disable Security/MarshalLoad
      end
    end
  end
end
