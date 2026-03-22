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

    # Container for a present value
    class Some
      # @param value [Object] the wrapped value
      def initialize(value)
        @value = value
      end

      # @return [Object] the wrapped value
      attr_reader :value

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

      alias_method :to_s, :inspect
    end

    # Represents an absent value
    class None
      include Singleton

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

      # Pattern matching support
      #
      # @param keys [Array<Symbol>, nil] the keys to deconstruct
      # @return [Hash] the deconstructed hash
      def deconstruct_keys(_keys)
        { value: nil, some: false, none: true }
      end

      # @return [Boolean] equality check
      def ==(other)
        other.is_a?(None)
      end

      # @return [String] string representation
      def inspect
        'None'
      end

      alias_method :to_s, :inspect
    end
  end
end
