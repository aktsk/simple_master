# frozen_string_literal: true

module SimpleMaster
  module ActiveRecord
    class BelongsToPolymorphicAssociation < ::ActiveRecord::Associations::BelongsToPolymorphicAssociation
      def find_target(async: false)
        klass = klass()
        if klass < Master
          foreign_key = owner.send(reflection.foreign_key)
          klass.find(foreign_key)
        else
          super
        end
      end
    end
  end
end
