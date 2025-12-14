# frozen_string_literal: true

module SimpleMaster
  module ActiveRecord
    class BelongsToMasterPolymorphicReflection < ::ActiveRecord::Reflection::BelongsToReflection
      def association_class
        BelongsToPolymorphicAssociation
      end
    end
  end
end
