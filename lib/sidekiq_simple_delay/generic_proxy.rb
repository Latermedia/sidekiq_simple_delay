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

    def method_missing(name, *args)
      worker_args = {
        'm' => name,
        'args' => args
      }

      # check to make sure there are no keyword or block args
      num_req_key_args = 0
      num_opt_key_args = 0
      num_var_key_args = 0
      num_block_args = 0

      @target.method(name).parameters.each do |param|
        case param[0]
        when :keyreq
          num_req_key_args += 1
        when :key
          num_opt_key_args += 1
        when :keyrest
          num_var_key_args += 1
        when :block
          num_block_args += 1
        end
      end

      uses_keyword_args = num_req_key_args > 0 || num_opt_key_args > 0 || num_var_key_args > 0
      raise ArgumentError, 'Cannot delay methods with named arguments' if uses_keyword_args

      raise ArgumentError, 'Cannot delay methods with named block argument' if num_block_args > 0

      # Calling class methods is always permitted
      if @target.is_a?(Class)
        worker_args['target_klass'] = @target.name
      # If this is an instance, it has to tell us what args we would use
      # to reinitialize it in the worker. If `#new` takes no args, that is also ok
      elsif @target.respond_to?(:initialize_args) || @target.method(:initialize).arity == 0
        worker_args['target_klass'] = @target.class.name
        # Verify it works with arrays, hashes, named arguments, and lists of arguments
        # These args will be passed to `simple_delay_initialize` if defined
        # or new otherwise
        worker_args['init_args'] =
          if @target.respond_to?(:initialize_args)
            @target.initialize_args
          else
            []
          end
      else
        # This is an instance of a class that is not simple delay compatible
        raise ArgumentError, "Objects of class #{@target.class} must implement " \
                             '#initialize_args or be calling a method with an arity of 0 to be delayed'
      end

      # the args have to be simple and convertable to JSON
      raise ArgumentError, 'args are not serializable, cannot use simple_delay' unless Utils.simple_object?(worker_args)

      wrapped =
        if @target.is_a?(Class)
          "SimpleDelayed=#{worker_args['target_klass']}::#{worker_args['m']}"
        else
          "SimpleDelayed=#{worker_args['target_klass']}##{worker_args['m']}"
        end

      push_args =
        {
          'class' => @performable,
          'args' => [worker_args],
          'wrapped' => wrapped
        }.merge(@opts)
      @performable.client_push(push_args)
    end
  end
end
