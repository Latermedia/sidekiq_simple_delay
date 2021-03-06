# frozen_string_literal: true

require 'sidekiq_simple_delay/delay_methods'

module SidekiqSimpleDelay
  # Methods to enable simple_delay functionality to work with ActiveRecord
  module ActiveRecord
    def self.included(base)
      base.include(SidekiqSimpleDelay::DelayMethods)
      base.extend(SidekiqSimpleDelay::DelayMethods)
      base.extend(ClassMethods)
    end

    # Args required to fetch this object from the database
    def initialize_args
      [send(self.class.primary_key)]
    end

    # Class methods to enable simple_delay functionality to work with ActiveRecord
    module ClassMethods
      # Take delay worker args and fetch record from database
      def simple_delay_initialize(*args)
        find(args[0])
      rescue ::ActiveRecord::RecordNotFound
        nil
      end
    end
  end
end
