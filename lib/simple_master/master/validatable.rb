# frozen_string_literal: true

module SimpleMaster
  class Master
    class Errors
      def initialize
        @errors = []
      end

      def add(attribute, type = :invalid, **options)
        @errors << [attribute, type, options]
      end

      delegate :empty?, :map, :each, :size, to: :@errors
    end

    # Validator works similar to ActiveRecord::Validations::UniquenessValidator.
    class UniquenessValidator < ActiveModel::EachValidator # :nodoc:
      def initialize(options)
        if options[:conditions] && !options[:conditions].respond_to?(:call)
          fail ArgumentError, "#{options[:conditions]} was passed as :conditions but is not callable. " \
                              "Pass a callable instead: `conditions: -> { where(approved: true) }`"
        end
        unless Array(options[:scope]).all? { |scope| scope.respond_to?(:to_sym) }
          fail ArgumentError, "#{options[:scope]} is not supported format for :scope option. " \
                              "Pass a symbol or an array of symbols instead: `scope: :user_id`"
        end
        super
        @klass = options[:class]
      end

      def validate_each(record, attribute, value)
        unless @klass.select { _1.send(attribute) == value }.one?
          error_options = options.except(:case_sensitive, :scope, :conditions)
          error_options[:value] = value

          record.errors.add(attribute, :taken, **error_options)
        end
      end
    end

    module Validatable
      extend ActiveSupport::Concern

      #: () -> bool
      def valid?
        _run_validate_callbacks
        # 大量なerrorsインスタンスを作ることを避けるため errors.empty? ではなく、直接参照する
        !Thread.current[:errors]&.[](self).present?
      end

      # @rbs skip
      def validate
        _run_validate_callbacks
      end

      def _run_validate_callbacks
        self.class._validate_callbacks.each do |validation_proc|
          instance_exec(&validation_proc)
        rescue => e
          errors.add(:base, "Error occurred while validation: #{e}")
        end
      end

      def errors
        Thread.current[:errors] ||= {}
        Thread.current[:errors][self] ||= Errors.new
      end

      def run_proc_or_call(symbol_or_proc)
        return send(symbol_or_proc) if symbol_or_proc.is_a? Symbol
        return instance_eval(&symbol_or_proc) if symbol_or_proc.arity == 1
        instance_exec(&symbol_or_proc)
      end

      def read_attribute_for_validation(attribute)
        send(attribute)
      end

      class_methods do
        # Validation procs to be called by current class on each record
        def _validate_procs
          @_validate_procs ||= []
        end

        # Validation procs to be called by current and parent classes on each record
        # (Similar to ActiveModel interface, but returns procs.)
        def _validate_callbacks
          if superclass < SimpleMaster::Master
            superclass._validate_callbacks + _validate_procs
          else
            _validate_procs
          end
        end

        # ref: https://github.com/ruby/gem_rbs_collection/blob/54fe53bbe56e5ff4e9bc2cb2c95426f13abe77ca/gems/activemodel/6.0/activemodel.rbs#L48-L50
        # @rbs!
        #   type condition[T] = Symbol | ^(T) [self: T] -> boolish
        #   type conditions[T] = condition[T] | Array[condition[T]]

        # (ActiveModel interface compliant.)
        # @rbs *validations: untyped
        # @rbs **options: { on?: Symbol | Array[Symbol], if?: conditions[instance], unless?: conditions[instance] }
        # @rbs &: ?{ (instance) [self: instance] -> void }
        # @rbs return: void
        def validate(*validations, **options, &)
          conditions = options.slice(:if, :unless)

          condition_procs = validation_condition_procs(conditions)

          validations.each do |validation|
            _validate_procs << proc {
              run_proc_or_call(validation) if condition_procs.all? { run_proc_or_call(_1) }
            }
          end
          _validate_procs << -> { instance_exec(&) if condition_procs.all? { run_proc_or_call(_1) } } if block_given?
        end

        # (ActiveModel interface compliant.)
        # @rbs skip
        def validates(*attributes)
          defaults = attributes.extract_options!.dup
          validations = defaults.slice!(:if, :unless, :on, :allow_blank, :allow_nil, :strict)

          fail ArgumentError, "You need to supply at least one attribute" if attributes.empty?
          fail ArgumentError, "You need to supply at least one validation" if validations.empty?
          warn "Option :on is not supported" if defaults[:on]
          warn "Option :strict is not supported" if defaults[:strict]

          defaults[:attributes] = attributes

          validations.each do |key, options|
            key = "#{key.to_s.camelize}Validator"

            validator = find_validator(key) || find_validator("ActiveModel::Validations::#{key}")

            fail ArgumentError, "Unknown validator: '#{key}'" unless validator

            next unless options

            validates_with(validator, defaults.merge(_parse_validates_options(options)))
          end
        end

        # (ActiveModel interface compliant.)
        # block args: (record, attribute, value)
        def validates_each(*attributes, **options)
          conditions = options.slice(:if, :unless)
          condition_procs = validation_condition_procs(conditions)
          attributes.each do |attribute|
            _validate_procs << proc {
              value = send(attribute)
              next if options[:allow_nil] && value.nil?
              next if options[:allow_blank] && value.blank?
              yield(self, attribute, value) if condition_procs.all? { run_proc_or_call(_1) }
            }
          end
        end

        # (ActiveModel interface compliant.)
        def validates_with(*args, &)
          options = args.extract_options!
          options[:class] = self

          conditions = options.slice(:if, :unless)

          condition_procs = validation_condition_procs(conditions)

          args.each do |klass|
            validator = klass.new(options.dup, &)

            _validate_procs << proc {
              validator.validate(self) if condition_procs.all? { run_proc_or_call(_1) }
            }
          end
        end

        private

        def _parse_validates_options(options)
          case options
          when TrueClass
            EMPTY_HASH
          when Hash
            options
          when Range, Array
            { in: options }
          else
            { with: options }
          end
        end

        def find_validator(key)
          const_get(key)
        rescue NameError
          false
        end

        # processing :if, :unless conditions
        def validation_condition_procs(conditions)
          conditions.flat_map do |key, value|
            if key == :if
              Array.wrap(value)
            elsif key == :unless
              Array.wrap(value).map { |v|
                -> { !run_proc_or_call(v) }
              }
            else
              EMPTY_ARRAY
            end
          end
        end
      end
    end
  end
end
