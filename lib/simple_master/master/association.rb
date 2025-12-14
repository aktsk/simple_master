# frozen_string_literal: true

module SimpleMaster
  class Master
    class Association
      autoload :BelongsToAssociation, "simple_master/master/association/belongs_to_association"
      autoload :BelongsToPolymorphicAssociation, "simple_master/master/association/belongs_to_polymorphic_association"
      autoload :HasManyAssociation, "simple_master/master/association/has_many_association"
      autoload :HasManyThroughAssociation, "simple_master/master/association/has_many_through_association"
      autoload :HasOneAssociation, "simple_master/master/association/has_one_association"

      attr_reader :name
      attr_reader :defined_at
      attr_reader :options

      def initialize(master_class, name, options)
        @name = name
        @defined_at = master_class
        @options = options
      end

      # Execute after definition phase.
      def target_class
        @target_class ||= find_class(defined_at, options[:class_name] || ActiveSupport::Inflector.classify(name))
      end

      def is_active_record?
        target_class < ::ActiveRecord::Base
      end

      def init(master_class)
      end

      def init_for_test(master_class)
      end

      private

      def find_class(current, class_name)
        loop do
          return current.const_get(class_name, false)
        rescue NameError => e
          raise e if current == current.module_parent

          current = current.module_parent
        end
      end
    end
  end
end
