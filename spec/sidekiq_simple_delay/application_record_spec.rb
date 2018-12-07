# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SidekiqSimpleDelay, run_tag: :application_record do
  before(:all) do
    require 'active_record_helper'
    SidekiqSimpleDelay.enable_delay_active_record!
  end

  describe 'delayed methods have been added to ApplicationRecord' do
    before(:each) do
      @owner = Owner.create(name: 'Les')
    end

    it 'simple_delay' do
      expect(ActiveRecord::Base.respond_to?(:simple_delay)).to eq(false)
      expect(ApplicationRecord.respond_to?(:simple_delay)).to eq(true)
      expect(Owner.respond_to?(:simple_delay)).to eq(true)
      expect(@owner.respond_to?(:simple_delay)).to eq(true)
    end

    it 'simple_delay_for' do
      expect(ActiveRecord::Base.respond_to?(:simple_delay_for)).to eq(false)
      expect(ApplicationRecord.respond_to?(:simple_delay_for)).to eq(true)
      expect(Owner.respond_to?(:simple_delay_for)).to eq(true)
      expect(@owner.respond_to?(:simple_delay_for)).to eq(true)
    end

    it 'simple_delay_until' do
      expect(ActiveRecord::Base.respond_to?(:simple_delay_until)).to eq(false)
      expect(ApplicationRecord.respond_to?(:simple_delay_until)).to eq(true)
      expect(Owner.respond_to?(:simple_delay_until)).to eq(true)
      expect(@owner.respond_to?(:simple_delay_until)).to eq(true)
    end

    it 'simple_delay_spread' do
      expect(ActiveRecord::Base.respond_to?(:simple_delay_spread)).to eq(false)
      expect(ApplicationRecord.respond_to?(:simple_delay_spread)).to eq(true)
      expect(Owner.respond_to?(:simple_delay_spread)).to eq(true)
      expect(@owner.respond_to?(:simple_delay_spread)).to eq(true)
    end
  end

  describe 'delayed worker' do
    context 'find the correct object and calls the correct method' do
      it 'no args' do
        owner = Owner.create(name: 'Les')
        Owner.create(name: 'Ian')

        expect do
          owner.simple_delay.my_name_is
        end.to change(SidekiqSimpleDelay::SimpleDelayedWorker.jobs, :size).by(1)

        expect(Owner).to receive(:trigger).with('Hello, my name is Les')
        Sidekiq::Worker.drain_all
      end

      it '1 arg' do
        owner = Owner.create(name: 'Les')
        Owner.create(name: 'Ian')

        expect do
          owner.simple_delay.greetings('Ian')
        end.to change(SidekiqSimpleDelay::SimpleDelayedWorker.jobs, :size).by(1)

        expect(Owner).to receive(:trigger).with("Hello, Ian. I'm Les")
        Sidekiq::Worker.drain_all
      end
    end
  end
end
