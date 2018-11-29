# frozen_string_literal: true

require 'sidekiq_simple_delay/utils'

module SidekiqSimpleDelay
  # Simple proxy object that handles enqueuing delay workers via `method_missing`
  class Proxy < Object
    def initialize(performable, target, options = {})
      @performable = performable
      @target = target
      @opts = options
    end

    def simple_delayable_instance?
      return false unless @target.respond_to?(:initialize_args)

      true
    end

    def method_missing(name, *args)
      worker_args = {
        'm' => name,
        'm_args' => args
      }

      method_args_sig = @target.method(name).parameters

      num_req_key_args = method_args_sig.select { |p| p[0] == :keyreq }.length
      num_opt_key_args = method_args_sig.select { |p| p[0] == :key }.length

      raise ::ArgumentError, 'Cannont delay methods with named arguments' if num_req_key_args > 0 || num_opt_key_args > 0

      if @target.class == ::Class
        worker_args['target_klass'] = @target.name
      else
        raise ::ArgumentError, "Unable to simple delay objects of type #{@target.class}" unless simple_delayable_instance?

        worker_args['target_klass'] = @target.class.name
        # verify it works with arrays, hashes, named arguments,
        # and lists of arguments
        worker_args['init_args'] = @target.initialize_args
      end

      raise ::ArgumentError, 'args are not simple, can not use simple_delay' unless Utils.simple_object?(worker_args)

      @performable.client_push({ 'class' => @performable, 'args' => [worker_args] }.merge(@opts))
    end
  end
end
