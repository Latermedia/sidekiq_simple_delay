# frozen_string_literal: true

require 'set'

module SidekiqSimpleDelay
  # utility methods
  class Utils
    class << self
      SYSTEM_SIMPLE_CLASSES = Set.new(
        [
          NilClass,
          TrueClass,
          FalseClass,
          String,
          Symbol
        ]
      ).freeze

      SYSTEM_SIMPLE_COMPLEX_CLASSES = Set.new(
        [
          Hash,
          Array
        ]
      ).freeze

      SYSTEM_SIMPLE_NUMERIC_CLASSES =
        if Gem::Version.new(RUBY_VERSION) >= Gem::Version.new('2.4.0')
          Set.new([Integer, Float]).freeze
        else
          Set.new([Fixnum, Bignum, Float]).freeze
        end

      def simple_object?(obj)
        klass = obj.class

        if SYSTEM_SIMPLE_COMPLEX_CLASSES.include?(klass)
          obj.all? { |o| simple_object?(o) }
        elsif SYSTEM_SIMPLE_CLASSES.include?(klass)
          true
        elsif SYSTEM_SIMPLE_NUMERIC_CLASSES.include?(klass)
          true
        else
          false
        end
      end
    end
  end
end
