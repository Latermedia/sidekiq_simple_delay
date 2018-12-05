# frozen_string_literal: true

require 'spec_helper'

class ClassDelayTest
end

RSpec.describe SidekiqSimpleDelay, run_tag: :enable_delay do
  before(:all) do
    SidekiqSimpleDelay.enable_delay!
  end

  describe 'delayed methods have been added' do
    it 'simple_delay' do
      expect(ClassDelayTest.respond_to?(:simple_delay)).to eq(true)
      expect(ClassDelayTest.new.respond_to?(:simple_delay)).to eq(false)
    end

    it 'simple_delay_for' do
      expect(ClassDelayTest.respond_to?(:simple_delay_for)).to eq(true)
      expect(ClassDelayTest.new.respond_to?(:simple_delay_for)).to eq(false)
    end

    it 'simple_delay_until' do
      expect(ClassDelayTest.respond_to?(:simple_delay_until)).to eq(true)
      expect(ClassDelayTest.new.respond_to?(:simple_delay_until)).to eq(false)
    end
  end
end
