# frozen_string_literal: true

module SimpleMaster
  module ActiveRecord
    module Extension
      extend ActiveSupport::Concern

      included do
        def master_dirty
          @master_dirty ||= {}
        end

        def initialize_dup(*_)
          @master_dirty = {}
          super
        end

        class << self
          def simple_master_connection
            self
          end

          def simple_master_association_options
            @simple_master_association_options ||= {}
          end

          def belongs_to(name, scope = nil, **options)
            unless options[:polymorphic]
              class_name = options[:class_name] || ActiveSupport::Inflector.classify(name)

              klass = compute_type("#{class_name}")
              if klass < SimpleMaster::Master
                return belongs_to_master(name, options)
              else
                return super
              end
            end

            reflection = BelongsToPolymorphicBuilder.build(self, name, scope, options)
            ::ActiveRecord::Reflection.add_reflection self, name, reflection
          end

          def belongs_to_master(name, options = EMPTY_HASH)
            simple_master_association_options[name] = options.dup

            class_name = options.delete(:class_name) || ActiveSupport::Inflector.classify(name)
            foreign_key = options.delete(:foreign_key) || ActiveSupport::Inflector.foreign_key(name)
            primary_key = options.delete(:primary_key) || :id

            warn "Options not supported! #{options}" unless options.empty?

            class_eval <<-RUBY, __FILE__, __LINE__ + 1
              Module.new {
                def #{name}
                  master_dirty[:#{name}] || #{class_name}.find_by_#{primary_key}(#{foreign_key})
                end

                def #{name}=(value)
                  if value == nil
                    self.#{foreign_key} = nil
                    master_dirty.delete(:#{name})
                  else
                    @_association_#{name}_source = self.#{foreign_key} = value.#{primary_key}

                    master_dirty[:#{name}] = value
                  end
                end

                def #{foreign_key}=(value)
                  master_dirty.delete(:#{name})
                  super
                end
              }.tap { |mod| include mod }

              before_save do
                if master_dirty[:#{name}]
                  master = master_dirty.delete(:#{name})
                  # Skip saving the association if the key was changed after assignment
                  if @_association_#{name}_source != #{foreign_key}
                    next
                  end
                  master.save
                  self.#{name} = master
                end
              end
            RUBY
          end

          def has_one(name, scope = nil, **options)
            return super if options[:through]

            class_name = options[:class_name] || ActiveSupport::Inflector.classify(name)

            klass = compute_type("#{class_name}")
            if klass < SimpleMaster::Master
              has_one_master(name, options)
            else
              super
            end
          end

          def has_one_master(name, options = EMPTY_HASH)
            simple_master_association_options[name] = options.dup

            class_name = options.delete(:class_name) || ActiveSupport::Inflector.classify(name)
            foreign_key = options.delete(:foreign_key) || ActiveSupport::Inflector.foreign_key(to_s)
            primary_key = options.delete(:primary_key) || :id

            warn "Options not supported! #{options}" unless options.empty?

            class_eval <<-RUBY, __FILE__, __LINE__ + 1
              Module.new {
                def #{name}
                  #{class_name}.find_by(:#{foreign_key}, #{primary_key})
                end
              }.tap { |mod| include mod }
            RUBY
          end

          def has_many(name, scope = nil, **options)
            return super if options[:through]

            class_name = options[:class_name] || ActiveSupport::Inflector.classify(name)

            klass = compute_type("#{class_name}")
            if klass < SimpleMaster::Master
              has_many_master(name, options)
            else
              super
            end
          end

          def has_many_master(name, options = EMPTY_HASH)
            simple_master_association_options[name] = options.dup

            class_name = options.delete(:class_name) || ActiveSupport::Inflector.classify(name)
            foreign_key = options.delete(:foreign_key) || ActiveSupport::Inflector.foreign_key(to_s)
            primary_key = options.delete(:primary_key) || :id
            inverse_of = options.delete(:inverse_of)

            warn "Options not supported! #{options}" unless options.empty?

            class_eval <<-RUBY, __FILE__, __LINE__ + 1
              Module.new {
                def #{name}
                  master_dirty[:#{name}] || #{class_name}.all_by(:#{foreign_key}, #{primary_key})
                end

                def #{name}=(values)
                  master_dirty[:#{name}] = values
                end
              }.tap { |mod| include mod }
            RUBY

            if inverse_of
              class_eval <<-RUBY, __FILE__, __LINE__ + 1
                after_save do
                  if master_dirty[:#{name}]
                    master_dirty.delete(:#{name}).each do |master|
                      master.#{inverse_of} = self
                      master.save
                    end
                  end
                end
              RUBY
            else
              class_eval <<-RUBY, __FILE__, __LINE__ + 1
                after_save do
                  if master_dirty[:#{name}]
                    master_dirty.delete(:#{name}).each do |master|
                      master.#{foreign_key} = self.id
                      master.save
                    end
                  end
                end
              RUBY
            end
          end
        end
      end
    end
  end
end
