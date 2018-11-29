# frozen_string_literal: true

require 'sidekiq_simple_delay/version'
# require 'sidekiq_simple_delay/class_methods'

# Sidekiq delay functionality with some restrictions
module SidekiqSimpleDelay
  def self.enable_delay!
    require 'sidekiq_simple_delay/class_methods'
    Module.__send__(:include, SidekiqSimpleDelay::Klass)
  end
end
