# frozen_string_literal: true

module SimpleMaster
  class Master
    class Association
      class BelongsToAssociation < self
        def foreign_key
          @foreign_key ||= (options[:foreign_key] || ActiveSupport::Inflector.foreign_key(name)).to_sym
        end

        def primary_key
          @primary_key ||= options[:primary_key] || target_class.primary_key || :id
        end

        def init(master_class)
          master_class.simple_master_module.class_eval <<-RUBY, __FILE__, __LINE__ + 1
            if #{target_class} < SimpleMaster::Master
              def #{name}
                return nil unless #{foreign_key}

                #{search_code}
              end
            else
              def #{name}
                return nil unless #{foreign_key}

                belongs_to_store[:#{name}] ||= #{target_class}.simple_master_connection.find_by_#{primary_key}(#{foreign_key})
              end
            end
          RUBY
        end

        def init_for_test(master_class)
          master_class.simple_master_module.class_eval <<-RUBY, __FILE__, __LINE__ + 1
            if #{target_class} < SimpleMaster::Master
              def #{name}
                return belongs_to_store[:#{name}] if belongs_to_store[:#{name}]
                return nil unless #{foreign_key}

                #{search_code}
              end
            else
              def #{name}
                return nil unless #{foreign_key}

                belongs_to_store[:#{name}] ||= #{target_class}.simple_master_connection.find_by_#{primary_key}(#{foreign_key})
              end
            end

            def #{name}=(value)
              @_association_#{name}_source = self.#{foreign_key} = value&.#{primary_key}
              belongs_to_store[:#{name}] = value
            end

            def _#{name}_target_save?
              # associationの代入後に別の値が代入された場合はassociationはsaveしない
              return false if @_association_#{name}_source != #{foreign_key}

              target = belongs_to_store[:#{name}]
              return false if target.nil?

              true
            end
          RUBY
        end

        private

        def search_code
          if primary_key == :id
            "#{target_class}.find_by_id(#{foreign_key})"
          else
            "#{target_class}.find_by(:#{primary_key}, #{foreign_key})"
          end
        end
      end
    end
  end
end
