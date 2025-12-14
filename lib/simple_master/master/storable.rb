# frozen_string_literal: true

module SimpleMaster
  class Master
    module Storable
      def master_storage(dataset = $current_dataset)
        dataset.table(self)
      end

      delegate :all, :all=, :id_hash, :id_hash=, :grouped_hash, :grouped_hash=, :class_method_cache, :class_method_cache=, :method_cache, to: :master_storage
      delegate :update_id_hash, :update_grouped_hash, :update_class_method_cache, :tap_instance_methods, :freeze_all, to: :master_storage
    end

    module SubClassStorable
      def master_storage(dataset = $current_dataset)
        dataset.table(sti_base_class).sub_table(self)
      end
    end
  end
end
