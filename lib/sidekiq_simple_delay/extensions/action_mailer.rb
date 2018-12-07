# frozen_string_literal: true

require 'sidekiq_simple_delay/delay_methods'
require 'sidekiq_simple_delay/delayed_mailer'

module SidekiqSimpleDelay
  # Methods to enable simple_delay functionality to work with ActiveRecord
  module ActionMailer
    def self.included(base)
      base.extend(SidekiqSimpleDelay::DelayMethods)
      base.extend(ClassMethods)
    end

    # Tell {DelayMethods} which delayed worker to use
    module ClassMethods
      def simple_delayed_worker
        SimpleDelayedMailer
      end
    end
  end
end
