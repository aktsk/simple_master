# frozen_string_literal: true

module SimpleMaster
  class Master
    class Association
      class BelongsToPolymorphicAssociation < self
        def foreign_key
          @foreign_key ||= (options[:foreign_key] || ActiveSupport::Inflector.foreign_key(name)).to_sym
        end

        def foreign_type
          @foreign_type ||= options[:foreign_type] || :"#{name}_type"
        end

        def foreign_type_class
          @foreign_type_class ||= :"#{foreign_type}_class"
        end

        def is_active_record?
          # target_class will be dynamically loaded.
          false
        end

        def target_class
          fail
        end

        def init(master_class)
          unless master_class.method_defined?(foreign_type_class)
            fail "[#{master_class}] Please specify `polymorphic_type: true` on polymorphic type column <#{name}>."
          end

          master_class.simple_master_module.class_eval <<-RUBY, __FILE__, __LINE__ + 1
            def #{name}
              return nil if #{foreign_type_class}.nil?

              if #{foreign_type_class} < SimpleMaster::Master
                #{foreign_type_class}.find_by_id(#{foreign_key})
              else
                belongs_to_store[:#{name}] ||= #{foreign_type_class}.simple_master_connection.find_by(id: #{foreign_key})
              end
            end
          RUBY
        end

        def init_for_test(master_class)
          master_class.simple_master_module.class_eval <<-RUBY, __FILE__, __LINE__ + 1
            def #{name}
              return nil if #{foreign_type_class}.nil?

              if #{foreign_type_class} < SimpleMaster::Master
                belongs_to_store[:#{name}] || #{foreign_type_class}.find_by_id(#{foreign_key})
              else
                belongs_to_store[:#{name}] ||= #{foreign_type_class}.simple_master_connection.find_by(id: #{foreign_key})
              end
            end

            def #{name}=(value)
              @_association_#{name}_source = self.#{foreign_key} = value&.id
              @_association_#{name}_class_source = self.#{foreign_type_class} = value&.class
              belongs_to_store[:#{name}] = value
            end

            def _#{name}_target_save?
              # Skip saving the association if the key changed after assignment
              return false if @_association_#{name}_source != #{foreign_key}
              return false if @_association_#{name}_class_source != #{foreign_type_class}

              target = belongs_to_store[:#{name}]
              return false if target.nil?

              true
            end
          RUBY
        end
      end
    end
  end
end
