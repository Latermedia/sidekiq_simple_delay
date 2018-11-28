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
          Symbol,
          Array,
          Hash
        ]
      ).freeze

      def numeric_simple_objects
        return @numeric_simple_objects if defined? @numeric_simple_objects

        ruby_version = Gem::Version.new(RUBY_VERSION)

        @numeric_simple_objects =
          if ruby_version >= Gem::Version.new('2.4.0')
            Set.new([Integer, Float]).freeze
          else
            Set.new([Fixnum, Bignum, Float]).freeze
          end
      end

      def user_simple_objects
        @user_simple_objects ||= Set.new
      end

      def simple_complex_objects
        @simple_complex_objects ||= Set.new([Hash, Array])
      end

      # Instance of klass must repond to each
      def add_simple_complex_object(klass)
        raise ArgumentError if klass.class != Class

        return false if simple_complex_objects.include?(klass)

        if klass.instance_methods.include?(:each)
          simple_complex_objects.add(klass)
          true
        else
          false
        end
      end

      def register_simple_object(klass)
        raise ArgumentError if klass.class != Class

        if user_simple_objects.include?(klass)
          false
        else
          user_simple_objects.add(klass)
          add_simple_complex_object(klass)

          true
        end
      end

      def simple_object?(obj)
        klass = obj.class

        if simple_complex_objects.include?(klass)
          obj.each do |o|
            return false unless simple_object?(o)
          end
          true
        elsif SYSTEM_SIMPLE_CLASSES.include?(klass)
          true
        elsif numeric_simple_objects.include?(klass)
          true
        elsif user_simple_objects.include?(klass)
          true
        else
          false
        end
      end
    end
  end
end
