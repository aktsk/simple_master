# frozen_string_literal: true

module SimpleMaster
  class Master
    # 検索用のメソッド定義
    module Filterable
      def find(id)
        id_hash.fetch(id)
      end

      def find_by_id(id)
        id_hash[id]
      end

      def find_by_ids(ids)
        id_hash.values_at(*ids).compact
      end

      def find_by_ids!(ids)
        id_hash.fetch_values(*ids)
      end

      def find_by(key, value)
        all_by(key, value).first
      end

      def all_by(key, value)
        grouped_hash.fetch(key).fetch(value) { EMPTY_ARRAY }
      end

      def all_by!(key, value)
        grouped_hash.fetch(key).fetch(value)
      end

      def all_in(key, values)
        # NOTE: Array#flatten が重いので、使わないようにしています
        grouped_hash.fetch(key).fetch_values(*values) { EMPTY_ARRAY }.flat_map(&:itself).freeze
      end

      def exists?(key)
        id_hash.key?(key)
      end

      delegate :pluck, :map, :first, :last, :each, :select, to: :all
    end
  end
end
