# frozen_string_literal: true

module SimpleMaster
  class Schema
    class << self
      TYPE = {
        integer: :integer,
        float: :float,
        string: :string,
        text: :string,
        json: :json,
        boolean: :boolean,
        datetime: :time,
        time: :time,
      }.freeze

      def generate(table_name)
        ar_columns = ::ActiveRecord::Base.connection.columns(table_name)
        ar_columns.each do |ar_column|
          info = []

          info << "  def_column :#{ar_column.name}"

          if ar_column.name == "type"
            info << "sti: true"
          elsif ar_column.name.end_with?("type") && ar_columns.any? { _1.name == "#{ar_column.name.delete_suffix('_type')}_id" }
            info << "polymorphic_type: true"
          elsif ar_column.name != "id" && TYPE[ar_column.type]
            info << "type: :#{TYPE[ar_column.type]}"
          end

          unless ar_column.default.nil?
            db_default_value = db_default_value(ar_column)

            info << "default: #{db_default_value.inspect}"
          end

          if ar_column.type == :time
            info << "db_type: :time"
          end

          puts info.join(", ")
        end

        nil
      end
    end
  end
end
