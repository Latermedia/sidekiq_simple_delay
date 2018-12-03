# frozen_string_literal: true

require 'sidekiq'

module SidekiqSimpleDelay
  # Worker that handles the simple_delayed functionality
  class SimpleDelayedWorker
    include Sidekiq::Worker

    def perform(args)
      target_klass = Object.const_get(args.fetch('target_klass'))

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
      method_args = args['args']

      target.__send__(method_name, *method_args)
    end
  end
end
