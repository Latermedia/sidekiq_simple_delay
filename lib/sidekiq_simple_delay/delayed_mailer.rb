# frozen_string_literal: true

require 'sidekiq'

module SidekiqSimpleDelay
  # Worker that handles the simple_delayed functionality for ActionMailers
  class SimpleDelayedMailer
    include Sidekiq::Worker

    def perform(args)
      target_klass = Object.const_get(args.fetch('target_klass'))

      method_name = args['m']
      method_args = args['args']

      msg = target_klass.__send__(method_name, *method_args)

      # The email method can return nil, which causes ActionMailer to return
      # an undeliverable empty message.
      raise "#{target.name}##{method_name} returned an undeliverable mail object" unless msg

      deliver(msg)
    end

    private

    def deliver(msg)
      if msg.respond_to?(:deliver_now)
        # Rails 4.2/5.0
        msg.deliver_now
      else
        # Rails 3.2/4.0/4.1
        msg.deliver
      end
    end
  end
end
