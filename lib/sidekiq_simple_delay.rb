# frozen_string_literal: true

require 'sidekiq_simple_delay/version'
require 'sidekiq_simple_delay/delay_methods'

# Sidekiq delay functionality with some restrictions
module SidekiqSimpleDelay
  class << self
    # Adds simple_delay class methods to all classes
    def enable_delay!
      enable_delay_instance!(Module)

      return unless defined?(::ActiveSupport)

      ActiveSupport.on_load(:active_record) do
        SidekiqSimpleDelay.enable_delay_active_record!
      end

      ActiveSupport.on_load(:action_mailer) do
        SidekiqSimpleDelay.enable_delay_application_mailer!
      end
    end

    # Adds simple_delay class methods to a class
    #
    # @param klass [Class] Class to add simple_delay class methods to
    def enable_delay_class!(klass)
      raise ArgumentError, 'klass must be a Class' unless klass.class.is_a?(Class)

      return if klass.singleton_class.included_modules.include?(SidekiqSimpleDelay::DelayMethods)

      klass.__send__(:extend, SidekiqSimpleDelay::DelayMethods)
    end

    # Adds simple_delay instance methods to class
    #
    # @param klass [Class] Class to add simple_delay instance methods to
    def enable_delay_instance!(klass)
      raise ArgumentError, 'klass must be a Class' unless klass.class.is_a?(Class)

      return if klass.included_modules.include?(SidekiqSimpleDelay::DelayMethods)

      klass.__send__(:include, SidekiqSimpleDelay::DelayMethods)
    end

    # Adds simple_delay functionality to ActiveRecord objects. Attempts to add to {ApplicationRecord} first,
    # the falls back to adding to {ActiveRecord::Base}.
    #
    # @param klass [Class] Class to add simple_delay functionality to. Must inherit from {ActiveRecord::Base}.
    def enable_delay_active_record!(klass = nil)
      klass =
        if !klass.nil?
          klass
        elsif defined?(::ApplicationRecord)
          ::ApplicationRecord
        elsif defined?(::ActiveRecord::Base)
          ::ActiveRecord::Base
        end

      raise ArgumentError, 'klass must be supplied' if klass.nil?
      raise ArgumentError, 'klass must be a class' unless klass.class.is_a?(Class)
      raise ArgumentError, 'klass must inherit from ActiveRecord::Base' unless klass.ancestors.any? { |c| c.name == 'ActiveRecord::Base' }

      ar_file = 'sidekiq_simple_delay/extensions/active_record'
      require ar_file unless defined? SidekiqSimpleDelay::ActiveRecord

      return if klass.included_modules.include?(SidekiqSimpleDelay::ActiveRecord)

      klass.__send__(:include, SidekiqSimpleDelay::ActiveRecord)
    end

    # Adds simple_delay functionality to ActionMailer objects. Attempts to add to {ApplicationMailer} first,
    # the falls back to adding to {ActionMailer::Base}.
    #
    # @param klass [Class] Class to add simple_delay functionality to. Must inherit from {ActionMailer::Base}.
    def enable_delay_application_mailer!(klass = nil)
      klass =
        if !klass.nil?
          klass
        elsif defined?(::ApplicationMailer)
          ::ApplicationMailer
        elsif defined?(::ActionMailer::Base)
          ::ActionMailer::Base
        end

      raise ArgumentError, 'klass must be supplied' if klass.nil?
      raise ArgumentError, 'klass must be a class' unless klass.class.is_a?(Class)
      raise ArgumentError, 'klass must inherit from ActionMailer::Base' unless klass.ancestors.any? { |c| c.name == 'ActionMailer::Base' }

      ar_file = 'sidekiq_simple_delay/extensions/action_mailer'
      require ar_file unless defined? SidekiqSimpleDelay::ActionMailer

      return if klass.included_modules.include?(SidekiqSimpleDelay::ActionMailer)

      klass.__send__(:include, SidekiqSimpleDelay::ActionMailer)
    end
  end
end
