# frozen_string_literal: true

require 'sidekiq_simple_delay/delay_worker'
require 'sidekiq_simple_delay/generic_proxy'

module SidekiqSimpleDelay
  # Aliased class methods to be added to Class
  module DelayMethods
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
