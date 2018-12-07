# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SidekiqSimpleDelay, run_tag: :action_mailer_base do
  before(:all) do
    require 'active_support'
    SidekiqSimpleDelay.enable_delay!
    require 'action_mailer_helper'
  end

  describe 'delayed methods have been added to ActionMailer::Base' do
    it 'simple_delay' do
      expect(ActionMailer::Base.respond_to?(:simple_delay)).to eq(true)
      expect(ApplicationMailer.respond_to?(:simple_delay)).to eq(true)
      expect(UserMailer.respond_to?(:simple_delay)).to eq(true)
    end

    it 'simple_delay_for' do
      expect(ActionMailer::Base.respond_to?(:simple_delay_for)).to eq(true)
      expect(ApplicationMailer.respond_to?(:simple_delay_for)).to eq(true)
      expect(UserMailer.respond_to?(:simple_delay_for)).to eq(true)
    end

    it 'simple_delay_until' do
      expect(ActionMailer::Base.respond_to?(:simple_delay_until)).to eq(true)
      expect(ApplicationMailer.respond_to?(:simple_delay_until)).to eq(true)
      expect(UserMailer.respond_to?(:simple_delay_until)).to eq(true)
    end

    it 'simple_delay_spread' do
      expect(ActionMailer::Base.respond_to?(:simple_delay_spread)).to eq(true)
      expect(ApplicationMailer.respond_to?(:simple_delay_spread)).to eq(true)
      expect(UserMailer.respond_to?(:simple_delay_spread)).to eq(true)
    end

    it 'mailer uses the correct delayed worker' do
      expect(UserMailer.simple_delayed_worker).to eq(SidekiqSimpleDelay::SimpleDelayedMailer)
    end

    it 'other class uses the correct delayed worker' do
      expect(MailerOtherKlass.simple_delayed_worker).to eq(SidekiqSimpleDelay::SimpleDelayedWorker)
    end
  end
end
