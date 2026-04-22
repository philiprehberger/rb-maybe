# frozen_string_literal: true

require 'singleton'
require_relative 'maybe/version'

module Philiprehberger
  module Maybe
    class Error < StandardError; end

    # Wrap a value in a Maybe container
    #
    # @param value [Object] the value to wrap
    # @return [Some, None] Some if value is non-nil, None otherwise
    def self.wrap(value)
      if value.nil?
        None.instance
      else
        Some.new(value)
      end
    end

    # Check if all arguments are Some
    #
    # @param maybes [Array<Some, None>] the Maybe values to check
    # @return [Boolean] true if all are Some
    def self.all?(*maybes)
      maybes.all?(&:some?)
    end

    # Return the first Some from the arguments, or None if all are None
    #
    # @param maybes [Array<Some, None>] the Maybe values to search
    # @return [Some, None] the first Some, or None
    def self.first_some(*maybes)
      maybes.find(&:some?) || None.instance
    end

    # Build a Maybe from a boolean gate
    #
    # If condition is truthy, wraps the given value (or the block's result if a block is provided).
    # If condition is falsy, returns None and the block is never invoked.
    #
    # @param condition [Object] truthy/falsy gate
    # @param value [Object] value to wrap when condition is truthy and no block is given
    # @yield optional block producing the value when condition is truthy
    # @return [Some, None] Some when the condition passes (and the value/block result is non-nil), None otherwise
    def self.from_bool(condition, value = nil, &block)
      return None.instance unless condition

      wrap(block ? block.call : value)
    end

    # Execute a block, converting raised exceptions and nil results into None
    #
    # @param error_classes [Array<Class>] exception classes to catch (defaults to StandardError)
    # @yield the block to execute
    # @return [Some, None] Some wrapping a non-nil result, or None if the block raises a caught exception or returns nil
    def self.try(*error_classes, &block)
      error_classes = [StandardError] if error_classes.empty?
      wrap(block.call)
    rescue *error_classes
      None.instance
    end

    # Container for a present value
    class Some
      include Enumerable

      # @param value [Object] the wrapped value
      def initialize(value)
        @value = value
      end

      # @return [Object] the wrapped value
      attr_reader :value

      # Yield the wrapped value for Enumerable support
      #
      # @yield [value] the wrapped value
      # @return [Enumerator, self]
      def each(&block)
        return to_enum(:each) unless block

        block.call(@value)
        self
      end

      # @return [Boolean] true
      def some?
        true
      end

      # @return [Boolean] false
      def none?
        false
      end

      # Transform the wrapped value
      #
      # @yield [value] the transformation block
      # @return [Some, None] the transformed Maybe
      def map(&block)
        Maybe.wrap(block.call(@value))
      end

      # Transform the wrapped value, expecting a Maybe return
      #
      # @yield [value] the transformation block returning a Maybe
      # @return [Some, None] the resulting Maybe
      def flat_map(&block)
        result = block.call(@value)
        raise Error, 'flat_map block must return a Maybe' unless result.is_a?(Some) || result.is_a?(None)

        result
      end

      # Filter the value based on a predicate
      #
      # @yield [value] the predicate block
      # @return [Some, None] Some if predicate is true, None otherwise
      def filter(&block)
        if block.call(@value)
          self
        else
          None.instance
        end
      end

      # Return self since value is present
      #
      # @return [Some] self
      def or_else(_default = nil)
        self
      end

      # Return the wrapped value since it is present
      #
      # @return [Object] the wrapped value
      def or_raise(_error_class = Error, _message = 'value is absent')
        @value
      end

      # Dig into nested structures
      #
      # @param keys [Array<Object>] keys to dig through
      # @return [Some, None] the result of digging
      def dig(*keys)
        result = @value
        keys.each do |key|
          result = case result
                   when Hash then result[key]
                   when Array then result[key]
                   else
                     return None.instance
                   end
          return None.instance if result.nil?
        end
        Maybe.wrap(result)
      end

      # Pattern matching support
      #
      # @param keys [Array<Symbol>, nil] the keys to deconstruct
      # @return [Hash] the deconstructed hash
      def deconstruct_keys(_keys)
        { value: @value, some: true, none: false }
      end

      # @return [Boolean] equality check
      def ==(other)
        other.is_a?(Some) && other.value == @value
      end

      # @return [String] string representation
      def inspect
        "Some(#{@value.inspect})"
      end

      # Access a single key (shorthand for dig)
      #
      # @param key [Object] the key to access
      # @return [Some, None] the result of digging with a single key
      def [](key)
        dig(key)
      end

      # Combine multiple Maybes into a single Maybe of an array
      #
      # @param others [Array<Some, None>] other Maybe values
      # @return [Some, None] Some with array of values if all are Some, None otherwise
      def zip(*others)
        values = [@value]
        others.each do |other|
          return None.instance if other.none?

          values << other.value
        end
        Some.new(values)
      end

      # Execute a block for side effects, returning self unchanged
      #
      # @yield [value] the block to execute
      # @return [Some] self
      def tap(&block)
        block.call(@value)
        self
      end

      # Inverse of #filter — return None when the predicate is truthy
      #
      # @yield [value] the predicate block
      # @return [Some, None] None if predicate is true, self otherwise
      def reject(&block)
        if block.call(@value)
          None.instance
        else
          self
        end
      end

      # Flatten a single level of Maybe nesting
      #
      # Some(Some(x)) becomes Some(x); Some(None) becomes None; Some(x) is unchanged.
      #
      # @return [Some, None] the flattened Maybe
      def flatten
        case @value
        when Some, None then @value
        else self
        end
      end

      # Check whether the wrapped value equals the given value
      #
      # @param value [Object] the value to compare against
      # @return [Boolean] true if the wrapped value equals the argument
      def contains?(value)
        @value == value
      end

      # Alias for #some? — matches Rails-style naming
      #
      # @return [Boolean] true
      def present?
        true
      end

      alias to_s inspect
    end

    # Represents an absent value
    class None
      include Singleton
      include Enumerable

      # Yield nothing for Enumerable support
      #
      # @return [Enumerator, self]
      def each(&block)
        return to_enum(:each) unless block

        self
      end

      # @return [nil] always nil
      def value
        nil
      end

      # @return [Boolean] false
      def some?
        false
      end

      # @return [Boolean] true
      def none?
        true
      end

      # No-op transformation
      #
      # @return [None] self
      def map
        self
      end

      # No-op transformation
      #
      # @return [None] self
      def flat_map
        self
      end

      # No-op filter
      #
      # @return [None] self
      def filter
        self
      end

      # Return the default value
      #
      # @param default [Object] the default value
      # @yield optional block providing default
      # @return [Some, None] the default wrapped in Maybe
      def or_else(default = nil, &block)
        value = block ? block.call : default
        Maybe.wrap(value)
      end

      # Raise an error since value is absent
      #
      # @param error_class [Class] the error class to raise
      # @param message [String] the error message
      # @raise [Error] always raises
      def or_raise(error_class = Error, message = 'value is absent')
        raise error_class, message
      end

      # Dig always returns None
      #
      # @return [None] self
      def dig(*)
        self
      end

      # Access a single key (shorthand for dig)
      #
      # @param _key [Object] the key to access
      # @return [None] self
      def [](_key)
        self
      end

      # Pattern matching support
      #
      # @param keys [Array<Symbol>, nil] the keys to deconstruct
      # @return [Hash] the deconstructed hash
      def deconstruct_keys(_keys)
        { value: nil, some: false, none: true }
      end

      # Convert None to Some via a block
      #
      # @yield the block providing a recovery value
      # @return [Some, None] the recovered Maybe
      def recover(&block)
        Maybe.wrap(block.call)
      end

      # Combine with other Maybes — always returns None
      #
      # @return [None] self
      def zip(*)
        self
      end

      # No-op tap, returns self
      #
      # @return [None] self
      def tap
        self
      end

      # No-op reject, returns self
      #
      # @return [None] self
      def reject
        self
      end

      # Flatten a None — returns self
      #
      # @return [None] self
      def flatten
        self
      end

      # None never contains anything
      #
      # @param _value [Object] ignored
      # @return [Boolean] false
      def contains?(_value)
        false
      end

      # Alias for #some? — matches Rails-style naming
      #
      # @return [Boolean] false
      def present?
        false
      end

      # @return [Boolean] equality check
      def ==(other)
        other.is_a?(None)
      end

      # @return [String] string representation
      def inspect
        'None'
      end

      alias to_s inspect
    end
  end
end
