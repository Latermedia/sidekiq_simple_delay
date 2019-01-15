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

def stub_proxy(obj, opts, method)
  proxy = SidekiqSimpleDelay::Proxy
  worker = SidekiqSimpleDelay::SimpleDelayedWorker

  retval = double(method => true)

  expect(proxy).to receive(:new).with(worker, obj, opts).and_return(retval)
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

      it 'enqueue simple_delay_spread' do
        expect do
          ValidSimpleObject.new.simple_delay_spread.method1
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

    context 'simple_delay_spread' do
      before(:each) do
        time_str = '2018-12-03 16:03:28 -0800'
        @time_f = 1_543_881_808.0

        allow(Time).to receive(:now).and_return(Time.parse(time_str))
      end

      it 'should enqueue immediately - 0 duration' do
        obj = ValidSimpleObject.new

        proxy_opts = {
          'at' => @time_f
        }
        stub_proxy(obj, proxy_opts, :method1)

        opts = {
          spread_duration: 0
        }
        obj.simple_delay_spread(opts).method1
      end

      it 'should enqueue immediately - neg duration' do
        obj = ValidSimpleObject.new

        proxy_opts = {
          'at' => @time_f
        }
        stub_proxy(obj, proxy_opts, :method1)

        opts = {
          spread_duration: -10
        }
        obj.simple_delay_spread(opts).method1
      end

      context 'rand' do
        before(:each) do
          @rand_val = 5
          allow(SidekiqSimpleDelay::Utils).to receive(:random_number).and_return(@rand_val)
        end

        it 'should enqueue within the next hour' do
          obj = ValidSimpleObject.new

          proxy_opts = {
            'at' => @time_f + @rand_val
          }
          stub_proxy(obj, proxy_opts, :method1)

          obj.simple_delay_spread.method1
        end

        it 'should enqueue within the next hour + 3 hours' do
          obj = ValidSimpleObject.new

          proxy_opts = {
            'at' => @time_f + @rand_val + 3.hours.to_f
          }
          stub_proxy(obj, proxy_opts, :method1)

          opts = {
            spread_in: 3.hours
          }

          obj.simple_delay_spread(opts).method1
        end

        it 'should enqueue within the next hour of give time' do
          obj = ValidSimpleObject.new

          t = Time.parse('Thu, 06 Dec 2018 16:47:58 PST -08:00')

          proxy_opts = {
            'at' => t.to_f + @rand_val
          }
          stub_proxy(obj, proxy_opts, :method1)

          opts = {
            spread_at: t
          }

          obj.simple_delay_spread(opts).method1
        end

        it 'should enqueue two jobs' do
          obj = ValidSimpleObject.new

          rand_val1 = 20_000
          rand_val2 = 15_500
          duration = 6.hours

          expect(SidekiqSimpleDelay::Utils).to receive(:random_number).and_return(rand_val1, rand_val2)
          expect(SidekiqSimpleDelay::Utils).to_not receive(:random_number).with(1.hour)

          opts = {
            spread_duration: duration
          }

          proxy_opts1 = {
            'at' => @time_f + rand_val1
          }
          stub_proxy(obj, proxy_opts1, :method1)
          obj.simple_delay_spread(opts).method1

          proxy_opts2 = {
            'at' => @time_f + rand_val2
          }
          stub_proxy(obj, proxy_opts2, :method2)
          obj.simple_delay_spread(opts).method2
        end
      end

      context 'mod' do
        it 'should enqueue a job based on mod_value' do
          obj = ValidSimpleObject.new

          proxy_opts = {
            'at' => @time_f + 1545.0
          }
          stub_proxy(obj, proxy_opts, :method1)

          opts = {
            spread_method: :mod,
            spread_mod_value: 12_345
          }

          obj.simple_delay_spread(opts).method1
        end

        it 'should enqueue a job based on mod_value and spread_duration' do
          obj = ValidSimpleObject.new

          proxy_opts = {
            'at' => @time_f + 345.0
          }
          stub_proxy(obj, proxy_opts, :method1)

          opts = {
            spread_method: :mod,
            spread_mod_value: 12_345,
            spread_duration: 10.minutes
          }

          obj.simple_delay_spread(opts).method1
        end

        it 'should enqueue a job based on spread_mod_method' do
          obj = ValidSimpleObject.new

          allow(obj).to receive(:get_my_mod_value).and_return(54_321)

          proxy_opts = {
            'at' => @time_f + 321.0
          }
          stub_proxy(obj, proxy_opts, :method1)

          opts = {
            spread_method: :mod,
            spread_mod_method: :get_my_mod_value
          }

          obj.simple_delay_spread(opts).method1
        end

        it 'should enqueue a job based on spread_mod_method method' do
          obj = ValidSimpleObject.new

          allow(obj).to receive(:get_my_mod_value).and_return(654_321)
          allow(obj).to receive(:spread_mod_method).and_return(:get_my_mod_value)

          proxy_opts = {
            'at' => @time_f + 2721.0
          }
          stub_proxy(obj, proxy_opts, :method1)

          opts = {
            spread_method: :mod
          }

          obj.simple_delay_spread(opts).method1
        end

        it 'should raise when we cannot find a mod_value' do
          obj = ValidSimpleObject.new

          opts = {
            spread_method: :mod
          }

          expect do
            obj.simple_delay_spread(opts).method1
          end.to raise_exception(::ArgumentError)
        end
      end

      context 'bad spread_method' do
        it 'should raise on bad spread_method' do
          obj = ValidSimpleObject.new

          opts = {
            spread_method: :not_valid
          }

          expect do
            obj.simple_delay_spread(opts).method1
          end.to raise_exception(::ArgumentError)
        end
      end
    end
  end
end
