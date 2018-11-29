# frozen_string_literal: true

require 'spec_helper'

require 'sidekiq_simple_delay/delay_methods'

class Klass1; end

class Klass2; end

class Klass3
  include SidekiqSimpleDelay::DelayMethods
  extend SidekiqSimpleDelay::DelayMethods
end

class Klass4
  SidekiqSimpleDelay.enable_delay_class!(self)
  SidekiqSimpleDelay.enable_delay_instance!(self)
end

RSpec.describe SidekiqSimpleDelay do
  before(:all) do
    SidekiqSimpleDelay.enable_delay_class!(Klass2)
    SidekiqSimpleDelay.enable_delay_instance!(Klass2)
  end

  describe 'delayed methods have been added' do
    it 'simple_delay' do
      [Klass2, Klass3, Klass4].each do |klass|
        expect(klass.respond_to?(:simple_delay)).to eq(true)
        expect(klass.new.respond_to?(:simple_delay)).to eq(true)
      end

      expect(Klass1.respond_to?(:simple_delay)).to eq(false)
      expect(Klass1.new.respond_to?(:simple_delay)).to eq(false)
    end

    it 'simple_delay_for' do
      [Klass2, Klass3, Klass4].each do |klass|
        expect(klass.respond_to?(:simple_delay_for)).to eq(true)
        expect(klass.new.respond_to?(:simple_delay_for)).to eq(true)
      end

      expect(Klass1.respond_to?(:simple_delay_for)).to eq(false)
      expect(Klass1.new.respond_to?(:simple_delay_for)).to eq(false)
    end

    it 'simple_delay_until' do
      [Klass2, Klass3, Klass4].each do |klass|
        expect(klass.respond_to?(:simple_delay_until)).to eq(true)
        expect(klass.new.respond_to?(:simple_delay_until)).to eq(true)
      end

      expect(Klass1.respond_to?(:simple_delay_until)).to eq(false)
      expect(Klass1.new.respond_to?(:simple_delay_until)).to eq(false)
    end
  end
end
