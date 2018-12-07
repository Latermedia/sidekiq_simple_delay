# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SidekiqSimpleDelay, run_tag: :action_mailer_single do
  before(:all) do
    require 'action_mailer_helper'
    SidekiqSimpleDelay.enable_delay_application_mailer!(UserMailer)
    SidekiqSimpleDelay.enable_delay_class!(MailerOtherKlass)
  end

  describe 'delayed methods have been added to ApplicationMailer' do
    it 'simple_delay' do
      expect(ActionMailer::Base.respond_to?(:simple_delay)).to eq(false)
      expect(ApplicationMailer.respond_to?(:simple_delay)).to eq(false)
      expect(UserMailer.respond_to?(:simple_delay)).to eq(true)
    end

    it 'simple_delay_for' do
      expect(ActionMailer::Base.respond_to?(:simple_delay_for)).to eq(false)
      expect(ApplicationMailer.respond_to?(:simple_delay_for)).to eq(false)
      expect(UserMailer.respond_to?(:simple_delay_for)).to eq(true)
    end

    it 'simple_delay_until' do
      expect(ActionMailer::Base.respond_to?(:simple_delay_until)).to eq(false)
      expect(ApplicationMailer.respond_to?(:simple_delay_until)).to eq(false)
      expect(UserMailer.respond_to?(:simple_delay_until)).to eq(true)
    end

    it 'mailer uses the correct delayed worker' do
      expect(UserMailer.simple_delayed_worker).to eq(SidekiqSimpleDelay::SimpleDelayedMailer)
    end

    it 'other class uses the correct delayed worker' do
      expect(MailerOtherKlass.simple_delayed_worker).to eq(SidekiqSimpleDelay::SimpleDelayedWorker)
    end
  end
end
