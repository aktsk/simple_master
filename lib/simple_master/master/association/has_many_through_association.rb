# frozen_string_literal: true

module SimpleMaster
  class Master
    class Association
      class HasManyThroughAssociation < self
        def foreign_key
          @foreign_key ||= (options[:foreign_key] || ActiveSupport::Inflector.foreign_key(defined_at.to_s)).to_sym
        end

        def through
          @through ||= options[:through]
        end

        def through_association
          @through_association ||=
            begin
              through_association = defined_at.all_has_many_associations.find { |ass| ass.name == through }

              if through_association.nil?
                fail "Association '#{through}' not found in has_many_associations. Use 'delegate' instead."
              end

              through_association
            end
        end

        delegate :target_class, to: :through_association

        def source
          @source ||= options[:source] || ActiveSupport::Inflector.singularize(name)
        end

        def primary_key
          @primary_key ||= options[:primary_key] || :id
        end

        def init(master_class)
          # check
          through_association

          master_class.simple_master_module.class_eval <<-RUBY, __FILE__, __LINE__ + 1
            def #{name}
              Array.wrap(#{through}).flat_map { |ass| ass.#{source} }.compact
            end
          RUBY
        end

        def init_for_test(master_class)
          master_class.simple_master_module.class_eval <<-RUBY, __FILE__, __LINE__ + 1
            def #{name}=(values)
              self.#{through} = values.map { |value|
                #{through_association.target_class}.new.tap do |through|
                  through.#{source} = value
                  #{"through.#{through_association.inverse_of} = self" if through_association.try(:inverse_of)}
                end
              }
            end
          RUBY
        end
      end
    end
  end
end
