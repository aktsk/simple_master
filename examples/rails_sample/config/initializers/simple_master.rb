# frozen_string_literal: true

require "json_loader"
require "yaml"

Rails.application.config.after_initialize do
  Rails.application.eager_load!

  SimpleMaster.init(for_test: Rails.env.test?)

  translations =
    begin
      YAML.load_file(Rails.root.join("fixtures/translations.yml")) || {}
    rescue Errno::ENOENT
      {}
    end

  globalize_proc = lambda do |klass, records|
    table_translation = translations[klass.table_name]
    column_names = klass.all_columns.filter_map { |column| column.name.to_s if column.options[:globalize] }
    return records if table_translation.blank? || column_names.empty?

    records.map do |record|
      record_translation = table_translation[record.id]
      next record unless record_translation

      record = record.dup if record.frozen?
      column_names.each do |column_name|
        translation = record_translation[column_name]
        next unless translation

        record.public_send(:"_globalized_#{column_name}=", translation.symbolize_keys)
      end
      record
    end
  end

  loader = JsonLoader.new(globalize_proc: globalize_proc)
  $current_dataset = SimpleMaster::Storage::Dataset.new(loader: loader)
  $current_dataset.load
end
