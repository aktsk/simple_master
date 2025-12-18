# frozen_string_literal: true

module SimpleMaster
  class Master
    # Provide save! helpers for test data
    module Editable
      extend ActiveSupport::Concern

      class_methods do
        def create(...)
          new(...).save
        end

        def create!(...)
          new(...).save!
        end
      end
      def dirty!
        @dirty = true
      end

      def new_record?
        id.nil? || self.class.id_hash[id] != self
      end

      def has_changes_to_save?
        !@dirty.nil?
      end

      def record_to_save
        # Assumes type_not_match? has already been checked
        return nil if type.nil?
        return @record_to_save if @record_to_save && @record_to_save.type == type

        @record_to_save = type.constantize.new
      end

      def type_not_match?
        self.class.sti_class? && type != self.class.to_s
      end

      # Use a generator that avoids ID collisions across classes
      @@generated_id = 0 # rubocop:disable Style/ClassVars
      def generate_id
        loop do
          @@generated_id += 1 # rubocop:disable Style/ClassVars
          break unless self.class.base_class.id_hash.key?(@@generated_id)
        end
        @@generated_id
      end

      # FOR TEST
      def save(**_options)
        save!
      end

      def save!(**_options)
        return if @saving
        @saving = true
        if id.nil?
          self.id = generate_id
        end

        # Save belongs_to.
        association_records = belongs_to_store.dup
        association_records.each do |association_name, record|
          next unless record

          unless send(:"_#{association_name}_target_save?")
            belongs_to_store.delete(association_name)
            next
          end

          record.save
          send(:"#{association_name}=", record)
          belongs_to_store.delete(association_name) if record.is_a?(SimpleMaster::Master)
        end

        if @dirty
          # Update this table
          if type_not_match?
            # If data would be created on the parent class, discard that instance and save separately
            record_to_save&.update!(attributes)
          else
            if new_record?
              id_updated = true
              current_and_super_classes_each { |klass| klass.master_storage.update(id, self) }
              SimpleMaster.logger.debug { "[SimpleMaster] Created: #{self.class}##{id}" }
            else
              current_and_super_classes_each { |klass| klass.master_storage.record_updated }
              SimpleMaster.logger.debug { "[SimpleMaster] Updated: #{self.class}##{id}" }
            end
          end
          @dirty = false
        end

        # save has_many
        association_records = has_many_store.dup

        association_records.each do |association_name, records|
          association = (self.class.all_has_many_associations | self.class.all_has_one_associations).find { |ass| ass.name == association_name }
          records.each do |record|
            if id_updated
              record.send(:"#{association.foreign_key}=", send(association.primary_key))
            end
            record.save
          end
          has_many_store.delete(association_name) if association.target_class < Master
        end

        @saving = false

        self
      end

      def current_and_super_classes_each
        klass = self.class
        yield klass

        loop do
          klass = klass.superclass
          break unless klass < Master
          next if klass.abstract_class?

          yield klass
        end
      end

      def update(attributes)
        update!(attributes)
        true
      end

      def update!(attributes)
        attributes.each do |key, value|
          send :"#{key}=", value
        end
        save!
      end

      def destroy
        destroy!
        true
      end

      def destroy!
        fail "Destroy is not allowed"
      end

      # NOTE: no freezing
      def freeze
      end
    end
  end
end
