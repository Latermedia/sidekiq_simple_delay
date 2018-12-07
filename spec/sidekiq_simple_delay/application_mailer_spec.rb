# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SidekiqSimpleDelay, run_tag: :application_mailer do
  before(:all) do
    require 'action_mailer_helper'
    SidekiqSimpleDelay.enable_delay_application_mailer!
    SidekiqSimpleDelay.enable_delay_class!(MailerOtherKlass)
  end

  describe 'delayed methods have been added to ApplicationMailer' do
    it 'simple_delay' do
      expect(ActionMailer::Base.respond_to?(:simple_delay)).to eq(false)
      expect(ApplicationMailer.respond_to?(:simple_delay)).to eq(true)
      expect(UserMailer.respond_to?(:simple_delay)).to eq(true)
    end

    it 'simple_delay_for' do
      expect(ActionMailer::Base.respond_to?(:simple_delay_for)).to eq(false)
      expect(ApplicationMailer.respond_to?(:simple_delay_for)).to eq(true)
      expect(UserMailer.respond_to?(:simple_delay_for)).to eq(true)
    end

    it 'simple_delay_until' do
      expect(ActionMailer::Base.respond_to?(:simple_delay_until)).to eq(false)
      expect(ApplicationMailer.respond_to?(:simple_delay_until)).to eq(true)
      expect(UserMailer.respond_to?(:simple_delay_until)).to eq(true)
    end

    it 'simple_delay_spread' do
      expect(ActionMailer::Base.respond_to?(:simple_delay_spread)).to eq(false)
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

  describe 'delayed worker' do
    context 'find the correct object and calls the correct method' do
      context 'no args' do
        it 'correct method' do
          expect do
            UserMailer.simple_delay.email1
          end.to change(SidekiqSimpleDelay::SimpleDelayedMailer.jobs, :size).by(1)

          expect(UserMailer).to receive(:trigger).with('hello')
          Sidekiq::Worker.drain_all
        end

        it 'mail is sent' do
          expect do
            UserMailer.simple_delay.email1
          end.to change(SidekiqSimpleDelay::SimpleDelayedMailer.jobs, :size).by(1)

          expect_any_instance_of(ActionMailer::MessageDelivery).to receive(:deliver_now)
          Sidekiq::Worker.drain_all
        end
      end

      context '1 arg' do
        it 'correct method' do
          expect do
            UserMailer.simple_delay.email2('things')
          end.to change(SidekiqSimpleDelay::SimpleDelayedMailer.jobs, :size).by(1)

          expect(UserMailer).to receive(:trigger).with('things')
          Sidekiq::Worker.drain_all
        end

        it 'mail is sent' do
          expect do
            UserMailer.simple_delay.email2('things')
          end.to change(SidekiqSimpleDelay::SimpleDelayedMailer.jobs, :size).by(1)

          expect_any_instance_of(ActionMailer::MessageDelivery).to receive(:deliver_now)
          Sidekiq::Worker.drain_all
        end
      end
    end
  end
end
