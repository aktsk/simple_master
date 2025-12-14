# frozen_string_literal: true

module SimpleMaster
  class Loader
    class DatasetLoader < Loader
      # options: dataset: ...
      def read_raw(table)
        dataset.table(table.klass)
      end

      def build_records(_klass, raw)
        raw.all
      end

      def dataset
        @options[:dataset]
      end
    end
  end
end
