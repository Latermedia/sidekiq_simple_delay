# frozen_string_literal: true

require 'spec_helper'

class ClassMethodTest
  class << self
    def trigger(params); end

    def method1
      trigger(nil)
    end

    def method2(arg1)
      trigger(arg1)
    end

    def method3(arg1, arg2)
      args = {
        arg1: arg1,
        arg2: arg2
      }
      trigger(args)
    end

    def method4(arg1, arg2:)
      args = {
        arg1: arg1,
        arg2: arg2
      }
      trigger(args)
    end
  end
end

RSpec.describe SidekiqSimpleDelay do
  before(:all) do
    SidekiqSimpleDelay.enable_delay_class!(ClassMethodTest)
  end

  describe 'delay class methods' do
    it 'enqueue simple_delay' do
      expect do
        ClassMethodTest.simple_delay.method1
      end.to change(SidekiqSimpleDelay::SimpleDelayedWorker.jobs, :size).by(1)

      expect(ClassMethodTest).to receive(:trigger)
      Sidekiq::Worker.drain_all
    end

    it 'enqueue simple_delay_for' do
      expect do
        ClassMethodTest.simple_delay_for(1.minute).method1
      end.to change(SidekiqSimpleDelay::SimpleDelayedWorker.jobs, :size).by(1)

      expect(ClassMethodTest).to receive(:trigger)
      Sidekiq::Worker.drain_all
    end

    it 'enqueue simple_delay_until' do
      expect do
        ClassMethodTest.simple_delay_until(1.day.from_now).method1
      end.to change(SidekiqSimpleDelay::SimpleDelayedWorker.jobs, :size).by(1)

      expect(ClassMethodTest).to receive(:trigger)
      Sidekiq::Worker.drain_all
    end

    it 'enqueue simple_delay_spread' do
      expect do
        ClassMethodTest.simple_delay_spread.method1
      end.to change(SidekiqSimpleDelay::SimpleDelayedWorker.jobs, :size).by(1)

      expect(ClassMethodTest).to receive(:trigger)
      Sidekiq::Worker.drain_all
    end

    context 'arguments' do
      it 'single sting argument' do
        ClassMethodTest.simple_delay.method2('simple')

        expect(ClassMethodTest).to receive(:trigger).with('simple')
        Sidekiq::Worker.drain_all
      end

      it 'single array argument' do
        ClassMethodTest.simple_delay.method2(['simple'])

        expect(ClassMethodTest).to receive(:trigger).with(['simple'])
        Sidekiq::Worker.drain_all
      end

      it 'single hash argument' do
        args = { 'simple' => 123 }
        ClassMethodTest.simple_delay.method2(args)

        expect(ClassMethodTest).to receive(:trigger).with(args)
        Sidekiq::Worker.drain_all
      end

      it 'multiple simple arguments' do
        ClassMethodTest.simple_delay.method3('things', 'words')

        expect(ClassMethodTest).to receive(:trigger).with(arg1: 'things', arg2: 'words')
        Sidekiq::Worker.drain_all
      end

      it 'multiple arguments' do
        ClassMethodTest.simple_delay.method3('things', ['words', 123])

        expect(ClassMethodTest).to receive(:trigger).with(arg1: 'things', arg2: ['words', 123])
        Sidekiq::Worker.drain_all
      end

      it 'method with keyword arg should raise' do
        expect do
          ClassMethodTest.simple_delay.method4('things', arg2: 'things')
        end.to raise_exception(::ArgumentError)
      end
    end
  end
end
