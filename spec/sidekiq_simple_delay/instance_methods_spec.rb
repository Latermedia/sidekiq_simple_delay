# frozen_string_literal: true

require 'spec_helper'

require 'sidekiq_simple_delay/delay_methods'

class InvalidSimpleObject
  include SidekiqSimpleDelay::DelayMethods

  def initialize(arg1); end

  def method1; end
end

class ValidSimpleObject
  include SidekiqSimpleDelay::DelayMethods

  class << self
    def trigger(params); end
  end

  def method1
    self.class.trigger(nil)
  end
end

class User
  include SidekiqSimpleDelay::DelayMethods

  class << self
    def trigger(params); end
  end

  attr_reader :first_name, :last_name

  def initialize(first_name, last_name)
    @first_name = first_name
    @last_name = last_name
  end

  def initialize_args
    [first_name, last_name]
  end

  def method1
    self.class.trigger("#{first_name} #{last_name}")
  end

  def method2(arg1)
    self.class.trigger("#{first_name} #{last_name} : #{arg1}")
  end

  def method3(arg1, arg2)
    args = {
      arg1: arg1,
      arg2: arg2,
      first_name: first_name,
      last_name: last_name
    }
    self.class.trigger(args)
  end

  def method4(arg1, arg2:)
    args = {
      arg1: arg1,
      arg2: arg2,
      first_name: first_name,
      last_name: last_name
    }
    trigger(args)
  end
end

class Actor
  include SidekiqSimpleDelay::DelayMethods

  class << self
    def trigger(params); end

    def simple_delay_initialize(first_name, last_name)
      new("#{first_name}_init", "#{last_name}_init")
    end
  end

  attr_reader :first_name, :last_name

  def initialize(first_name, last_name)
    @first_name = first_name
    @last_name = last_name
  end

  def initialize_args
    [first_name, last_name]
  end

  def method1
    self.class.trigger("#{first_name} #{last_name}")
  end

  def method2(arg1)
    self.class.trigger("#{first_name} #{last_name} : #{arg1}")
  end

  def method3(arg1, arg2)
    args = {
      arg1: arg1,
      arg2: arg2,
      first_name: first_name,
      last_name: last_name
    }
    self.class.trigger(args)
  end

  def method4(arg1, arg2:)
    args = {
      arg1: arg1,
      arg2: arg2,
      first_name: first_name,
      last_name: last_name
    }
    trigger(args)
  end
end

RSpec.describe SidekiqSimpleDelay do
  before(:all) do
    # SidekiqSimpleDelay.enable_delay_instance!(Klass2)
  end

  describe 'delay instance methods' do
    context 'invalid object' do
      it 'raise' do
        obj = InvalidSimpleObject.new('things')

        expect do
          obj.simple_delay.method1
        end.to raise_exception(::ArgumentError)
      end
    end

    context 'simple object' do
      it 'enqueue simple_delay' do
        expect do
          ValidSimpleObject.new.simple_delay.method1
        end.to change(SidekiqSimpleDelay::SimpleDelayedWorker.jobs, :size).by(1)

        expect(ValidSimpleObject).to receive(:trigger).with(nil)
        Sidekiq::Worker.drain_all
      end

      it 'enqueue simple_delay_for' do
        expect do
          ValidSimpleObject.new.simple_delay_for(1.minute).method1
        end.to change(SidekiqSimpleDelay::SimpleDelayedWorker.jobs, :size).by(1)

        expect(ValidSimpleObject).to receive(:trigger).with(nil)
        Sidekiq::Worker.drain_all
      end

      it 'enqueue simple_delay_until' do
        expect do
          ValidSimpleObject.new.simple_delay_until(1.day.from_now).method1
        end.to change(SidekiqSimpleDelay::SimpleDelayedWorker.jobs, :size).by(1)

        expect(ValidSimpleObject).to receive(:trigger).with(nil)
        Sidekiq::Worker.drain_all
      end
    end

    context 'complex object' do
      let(:first_name) { 'Les' }
      let(:last_name) { 'Fletcher' }

      describe 'new' do
        before(:each) do
          @user = User.new(first_name, last_name)
        end

        it 'call method - 0 args' do
          expect do
            @user.simple_delay.method1
          end.to change(SidekiqSimpleDelay::SimpleDelayedWorker.jobs, :size).by(1)

          expect(User).to receive(:trigger).with("#{first_name} #{last_name}")
          Sidekiq::Worker.drain_all
        end

        it 'call method - 1 arg' do
          expect do
            @user.simple_delay.method2('things')
          end.to change(SidekiqSimpleDelay::SimpleDelayedWorker.jobs, :size).by(1)

          expect(User).to receive(:trigger).with("#{first_name} #{last_name} : things")
          Sidekiq::Worker.drain_all
        end

        it 'call method - 2 args' do
          expect do
            @user.simple_delay.method3('things', 'stuff')
          end.to change(SidekiqSimpleDelay::SimpleDelayedWorker.jobs, :size).by(1)

          args = {
            arg1: 'things',
            arg2: 'stuff',
            first_name: first_name,
            last_name: last_name
          }
          expect(User).to receive(:trigger).with(args)
          Sidekiq::Worker.drain_all
        end

        it 'method with keyword arg should raise' do
          expect do
            @user.simple_delay.method4('things', arg2: 'things')
          end.to raise_exception(::ArgumentError)
        end
      end

      describe 'simple_delay_initialize' do
        before(:each) do
          @actor = Actor.new(first_name, last_name)
        end

        it 'call method - 0 args' do
          expect do
            @actor.simple_delay.method1
          end.to change(SidekiqSimpleDelay::SimpleDelayedWorker.jobs, :size).by(1)

          expect(Actor).to receive(:trigger).with("#{first_name}_init #{last_name}_init")
          Sidekiq::Worker.drain_all
        end

        it 'call method - 1 arg' do
          expect do
            @actor.simple_delay.method2('things')
          end.to change(SidekiqSimpleDelay::SimpleDelayedWorker.jobs, :size).by(1)

          expect(Actor).to receive(:trigger).with("#{first_name}_init #{last_name}_init : things")
          Sidekiq::Worker.drain_all
        end

        it 'call method - 2 args' do
          expect do
            @actor.simple_delay.method3('things', 'stuff')
          end.to change(SidekiqSimpleDelay::SimpleDelayedWorker.jobs, :size).by(1)

          args = {
            arg1: 'things',
            arg2: 'stuff',
            first_name: "#{first_name}_init",
            last_name: "#{last_name}_init"
          }
          expect(Actor).to receive(:trigger).with(args)
          Sidekiq::Worker.drain_all
        end

        it 'method with keyword arg should raise' do
          expect do
            @actor.simple_delay.method4('things', arg2: 'things')
          end.to raise_exception(::ArgumentError)
        end
      end
    end
  end
end
