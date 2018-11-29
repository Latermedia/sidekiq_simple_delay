# frozen_string_literal: true

require 'sidekiq_simple_delay/version'
require 'sidekiq_simple_delay/delay_methods'

# Sidekiq delay functionality with some restrictions
module SidekiqSimpleDelay
  class << self
    # Adds simple_delay class methods to all classes
    def enable_delay!
      enable_delay_instance!(Module)
    end

    # Adds simple_delay class methods to klass
    def enable_delay_class!(klass)
      raise ::ArgumentError, 'klass must be a Class' if klass.class != Class

      klass.__send__(:extend, SidekiqSimpleDelay::DelayMethods)
    end

    # Adds simple_delay instance methods to klass
    def enable_delay_instance!(klass)
      raise ::ArgumentError, 'klass must be a Class' if klass.class != Class

      klass.__send__(:include, SidekiqSimpleDelay::DelayMethods)
    end
  end
end
