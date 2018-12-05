# frozen_string_literal: true

require 'sidekiq_simple_delay/delay_worker'
require 'sidekiq_simple_delay/generic_proxy'

module SidekiqSimpleDelay
  # Aliased class methods to be added to Class
  module DelayMethods
    # Immediately enqueue a job to handle the delayed action
    #
    # @param options [Hash] options similar to Sidekiq's `perform_async`
    def simple_sidekiq_delay(options = {})
      Proxy.new(simple_delayed_worker, self, options)
    end

    # Enqueue a job to handle the delayed action after an elapsed interval
    #
    # @param interval [#to_f] Number of seconds to wait. `to_f` will be called on
    #   this argument to convert to seconds.
    # @param options [Hash] options similar to Sidekiq's `perform_in`
    def simple_sidekiq_delay_for(interval, options = {})
      Proxy.new(simple_delayed_worker, self, options.merge('at' => Time.now.to_f + interval.to_f))
    end

    # Enqueue a job to handle the delayed action after at a certain time
    #
    # @param timestamp [#to_f] Timestamp to execute job at. `to_f` will be called on
    #   this argument to convert to a timestamp.
    # @param options [Hash] options similar to Sidekiq's `perform_at`
    def simple_sidekiq_delay_until(timestamp, options = {})
      Proxy.new(simple_delayed_worker, self, options.merge('at' => timestamp.to_f))
    end

    # Tell {DelayMethods} which delayed worker to use
    def simple_delayed_worker
      SimpleDelayedWorker
    end

    alias simple_delay simple_sidekiq_delay
    alias simple_delay_for simple_sidekiq_delay_for
    alias simple_delay_until simple_sidekiq_delay_until
  end
end
