# frozen_string_literal: true

require 'sidekiq'
require 'sidekiq_simple_delay/utils'
require 'sidekiq_simple_delay/generic_proxy'

# Sidekiq delay functionality with some restrictions
module SidekiqSimpleDelay
  class SimpleDelayedWorker
    include Sidekiq::Worker

    def perform(args)
      target_klass = Object.const_get(args['target_klass'])

      target =
        if args.key?('init_args')
          if target_klass.respond_to?(:simple_delay_initialize)
            target_klass.simple_delay_initialize(*args['init_args'])
          else
            target_klass.new(*args['init_args'])
          end
        else
          target_klass
        end

      method_name = args['m']
      method_args = args['m_args']

      target.__send__(method_name, *method_args)
    end
  end

  module Klass
    def simple_sidekiq_delay(options = {})
      Proxy.new(SimpleDelayedWorker, self, options)
    end

    def simple_sidekiq_delay_for(interval, options = {})
      Proxy.new(SimpleDelayedWorker, self, options.merge('at' => Time.now.to_f + interval.to_f))
    end

    def simple_sidekiq_delay_until(timestamp, options = {})
      Proxy.new(SimpleDelayedWorker, self, options.merge('at' => timestamp.to_f))
    end

    alias simple_delay simple_sidekiq_delay
    alias simple_delay_for simple_sidekiq_delay_for
    alias simple_delay_until simple_sidekiq_delay_until
  end
end
