# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SidekiqSimpleDelay, run_tag: :active_record_base do
  before(:all) do
    require 'active_support'
    SidekiqSimpleDelay.enable_delay!
    require 'active_record_helper'
  end

  describe 'delayed methods have been added to ActiveRecord::Base' do
    before(:each) do
      @owner = Owner.create(name: 'Les')
    end

    it 'simple_delay' do
      expect(ActiveRecord::Base.respond_to?(:simple_delay)).to eq(true)
      expect(ApplicationRecord.respond_to?(:simple_delay)).to eq(true)
      expect(Owner.respond_to?(:simple_delay)).to eq(true)
      expect(@owner.respond_to?(:simple_delay)).to eq(true)
    end

    it 'simple_delay_for' do
      expect(ActiveRecord::Base.respond_to?(:simple_delay_for)).to eq(true)
      expect(ApplicationRecord.respond_to?(:simple_delay_for)).to eq(true)
      expect(Owner.respond_to?(:simple_delay_for)).to eq(true)
      expect(@owner.respond_to?(:simple_delay_for)).to eq(true)
    end

    it 'simple_delay_until' do
      expect(ActiveRecord::Base.respond_to?(:simple_delay_until)).to eq(true)
      expect(ApplicationRecord.respond_to?(:simple_delay_until)).to eq(true)
      expect(Owner.respond_to?(:simple_delay_until)).to eq(true)
      expect(@owner.respond_to?(:simple_delay_until)).to eq(true)
    end

    it 'simple_delay_spread' do
      expect(ActiveRecord::Base.respond_to?(:simple_delay_spread)).to eq(true)
      expect(ApplicationRecord.respond_to?(:simple_delay_spread)).to eq(true)
      expect(Owner.respond_to?(:simple_delay_spread)).to eq(true)
      expect(@owner.respond_to?(:simple_delay_spread)).to eq(true)
    end
  end
end
