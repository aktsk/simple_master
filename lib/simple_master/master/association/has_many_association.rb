# frozen_string_literal: true

module SimpleMaster
  class Master
    class Association
      class HasManyAssociation < self
        def foreign_key
          @foreign_key ||= (options[:foreign_key] || ActiveSupport::Inflector.foreign_key(defined_at.to_s)).to_sym
        end

        def inverse_of
          @inverse_of ||= options[:inverse_of] || ActiveSupport::Inflector.underscore(defined_at.to_s)
        end

        def primary_key
          @primary_key ||= options[:primary_key] || defined_at.primary_key || :id
        end

        def init(master_class)
          master_class.simple_master_module.class_eval <<-RUBY, __FILE__, __LINE__ + 1
            if #{target_class} < SimpleMaster::Master
              def #{name}
                #{target_class}.all_by(:#{foreign_key}, #{primary_key})
              end
            else
              def #{name}
                has_many_store[:#{name}] ||= #{target_class}.simple_master_connection.where(:#{foreign_key} => #{primary_key}).to_a
              end
            end
          RUBY
        end

        def init_for_test(master_class)
          master_class.simple_master_module.class_eval <<-RUBY, __FILE__, __LINE__ + 1
            if #{target_class} < SimpleMaster::Master
              def #{name}
                has_many_store[:#{name}] || #{target_class}.all_by(:#{foreign_key}, #{primary_key})
              end
            else
              def #{name}
                has_many_store[:#{name}] ||= #{target_class}.simple_master_connection.where(:#{foreign_key} => #{primary_key}).to_a
              end
            end

            def #{name}=(values)
              has_many_store[:#{name}] = values
            end
          RUBY
        end
      end
    end
  end
end
