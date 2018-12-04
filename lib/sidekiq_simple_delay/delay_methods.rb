# frozen_string_literal: true

require 'sidekiq_simple_delay/delay_worker'
require 'sidekiq_simple_delay/generic_proxy'
require 'sidekiq_simple_delay/utils'

module SidekiqSimpleDelay
  # Aliased class methods to be added to Class
  module DelayMethods
    # Immediately enqueue a job to handle the delayed action
    #
    # @param options [Hash] options similar to Sidekiq's `perform_async`
    def simple_sidekiq_delay(options = {})
      Proxy.new(SimpleDelayedWorker, self, options)
    end

    # Enqueue a job to handle the delayed action after an elapsed interval
    #
    # @param interval [#to_f] Number of seconds to wait. `to_f` will be called on
    #   this argument to convert to seconds.
    # @param options [Hash] options similar to Sidekiq's `perform_in`
    def simple_sidekiq_delay_for(interval, options = {})
      Proxy.new(SimpleDelayedWorker, self, options.merge('at' => Time.now.to_f + interval.to_f))
    end

    # Enqueue a job to handle the delayed action after at a certain time
    #
    # @param timestamp [#to_f] Timestamp to execute job at. `to_f` will be called on
    #   this argument to convert to a timestamp.
    # @param options [Hash] options similar to Sidekiq's `perform_at`
    def simple_sidekiq_delay_until(timestamp, options = {})
      Proxy.new(SimpleDelayedWorker, self, options.merge('at' => timestamp.to_f))
    end

    # Enqueue a job to handle the delayed action in a given timeframe
    #
    # @param timestamp [#to_f] Timestamp to execute job at. `to_f` will be called on
    #   this argument to convert to a timestamp.
    # @param options [Hash] options similar to Sidekiq's `perform_at`
    # @option options [Number] :spread_duration Size of window to spread workers out over
    # @option options [Number] :spread_in Start of window offset from now
    # @option options [Number] :spread_at Start of window offset timestamp
    # @option options [rand|mod] :spread_method perform either a random or modulo spread,
    #   default: *:rand*
    # @option options [Number] :spread_mod_value value to use for determining mod offset
    # @option options [Symbol] :spread_mod_method method to call to get the value to use
    #   for determining mod offset
    def simple_sidekiq_delay_spread(options = {})
      spread_duration = Utils.extract_option(options, :spread_duration, 1.hour).to_f
      spread_in = Utils.extract_option(options, :spread_in, 0).to_f
      spread_at = Utils.extract_option(options, :spread_at)
      spread_method = Utils.extract_option(options, :spread_method, :rand)
      spread_mod_value = Utils.extract_option(options, :spread_mod_value)
      spread_mod_method = Utils.extract_option(options, :spread_mod_method)

      spread_duration = 0 if spread_duration < 0
      spread_in = 0 if spread_in < 0

      spread =
        # kick of immediately if the duration is 0
        if spread_duration.zero?
          0
        else
          case spread_method.to_sym
          when :rand
            SecureRandom.random_number(spread_duration)
          when :mod
            mod_value =
              # The mod value has been supplied
              if !spread_mod_value.nil?
                spread_mod_value
              # Call the supplied method on the target object to get mod value
              elsif !spread_mod_method.nil?
                send(spread_mod_method)
              # Call `spread_mod_method` on target object to get mod value
              elsif respond_to?(:spread_mod_method)
                send(send(:spread_mod_method))
              else
                raise ArgumentError, 'must specify `spread_mod_value` or `spread_mod_method` or taget must respond to `spread_mod_method`'
              end

            # calculate the mod based offset
            mod_value % spread_duration
          else
            raise ArgumentError, "spread_method must :rand or :mod, `#{spread_method} is invalid`"
          end
        end

      t =
        if !spread_at.nil?
          # add spread to a timestamp
          spread_at.to_f + spread
        elsif !spread_in.nil?
          # add spread to no plus constant offset
          Time.now.to_f + spread_in.to_f + spread
        else
          # add spread to current time
          Time.now.to_f + spread
        end

      Proxy.new(SimpleDelayedWorker, self, options.merge('at' => t))
    end

    alias simple_delay simple_sidekiq_delay
    alias simple_delay_for simple_sidekiq_delay_for
    alias simple_delay_until simple_sidekiq_delay_until
    alias simple_delay_spread simple_sidekiq_delay_spread
  end
end
