# frozen_string_literal: true

module SimpleMaster
  module ActiveRecord
    class BelongsToPolymorphicBuilder < ::ActiveRecord::Associations::Builder::BelongsTo
      def self.create_reflection(model, name, scope, options, &)
        fail ArgumentError, "association names must be a Symbol" unless name.is_a?(Symbol)

        validate_options(options)

        extension = define_extensions(model, name, &)
        options[:extend] = [*options[:extend], extension] if extension

        scope = build_scope(scope)

        fail "not implemented" if options[:through]
        BelongsToMasterPolymorphicReflection.new(name, scope, options, model)
      end
    end
  end
end
