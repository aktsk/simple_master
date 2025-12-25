# frozen_string_literal: true

module SimpleMaster
  class Master
    # Query in database
    module Queryable
      def query_select_all
        connection.select_all("SELECT * from #{table_name}")
      end

      def query_upsert_records(records, batch_size: 10000)
        insert_queries(records, true, batch_size: batch_size).each do |sql|
          connection.execute(sql)
        end
      end

      def insert_queries(records, on_duplicate_key_update = false, batch_size: 10000)
        return [] if records.empty?

        column_names = all_columns.map(&:name)
        db_column_names = all_columns.map(&:db_column_name)
        sql_columns = db_column_names.map { "`#{_1}`" }.join(", ").then { "(#{_1})" }

        sql_column_methods = column_names.map { |column_name| :"#{column_name}_value_for_sql" }
        current_time = "'#{Time.now.utc.strftime('%Y-%m-%d %H:%M:%S')}'"

        if on_duplicate_key_update
          sql_update = db_column_names.filter_map { |column_name| "`#{column_name}` = new.#{column_name}" if column_name != :created_at }.join(", ")
          on_duplicate_key_update_sql = " AS new ON DUPLICATE KEY UPDATE #{sql_update}"
        else
          on_duplicate_key_update_sql = ""
        end

        records.each_slice(batch_size).map { |sliced_records|
          values_sql =
            sliced_records.map { |record|
              sql_column_methods
                .zip(column_names)
                .map { |method_name, column_name|
                  if [:updated_at, :created_at].include?(column_name)
                    current_time
                  else
                    record.send(method_name)
                  end
              }.join(", ").then { "(#{_1})" }
            }.join(", \n")

          "INSERT INTO `#{table_name}` \n#{sql_columns} VALUES \n#{values_sql}#{on_duplicate_key_update_sql};\n"
        }
      end

      def sqlite_insert_query(records)
        insert_queries(records, false).join("\n").gsub("\\\\", "\\")
      end

      def query_delete_all
        connection.execute(delete_all_query)
      end

      def delete_all_query
        "DELETE FROM #{table_name};"
      end

      def table_available?
        connection.table_exists? table_name
      rescue
        false
      end

      def connection
        ::ActiveRecord::Base.connection
      end
    end
  end
end
