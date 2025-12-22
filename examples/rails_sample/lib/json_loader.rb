# frozen_string_literal: true

require "json"

# Loads master data from JSON files under examples/rails_sample/fixtures/masters/<table>.json
class JsonLoader < SimpleMaster::Loader
  FIXTURE_DIR = File.expand_path("../fixtures/masters", __dir__)

  def read_raw(table)
    path = File.join(FIXTURE_DIR, "#{table.klass.table_name}.json")
    File.read(path)
  end

  def build_records(klass, raw)
    record_hashes = JSON.parse(raw)

    if klass.sti_class?
      sti_column_name = klass.sti_column.to_s

      record_hashes.map do |record_hash|
        sti_klass = record_hash[sti_column_name].constantize
        sti_klass.new(record_hash)
      end
    else
      record_hashes.map do |record_hash|
        klass.new(record_hash)
      end
    end
  end
end
