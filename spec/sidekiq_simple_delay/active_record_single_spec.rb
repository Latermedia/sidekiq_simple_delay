# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SidekiqSimpleDelay, run_tag: :active_record_single do
  before(:all) do
    require 'active_record_helper'
    SidekiqSimpleDelay.enable_delay_active_record!(Owner)
  end

  describe 'delayed methods have been added to ApplicationRecord' do
    before(:each) do
      @owner = Owner.create(name: 'Les')
      @pet = Pet.create(name: 'Les', owner: @owner)
    end

    it 'simple_delay' do
      expect(ActiveRecord::Base.respond_to?(:simple_delay)).to eq(false)
      expect(ApplicationRecord.respond_to?(:simple_delay)).to eq(false)

      expect(Owner.respond_to?(:simple_delay)).to eq(true)
      expect(@owner.respond_to?(:simple_delay)).to eq(true)

      expect(Pet.respond_to?(:simple_delay)).to eq(false)
      expect(@pet.respond_to?(:simple_delay)).to eq(false)
    end

    it 'simple_delay_for' do
      expect(ActiveRecord::Base.respond_to?(:simple_delay_for)).to eq(false)
      expect(ApplicationRecord.respond_to?(:simple_delay_for)).to eq(false)

      expect(Owner.respond_to?(:simple_delay_for)).to eq(true)
      expect(@owner.respond_to?(:simple_delay_for)).to eq(true)

      expect(Pet.respond_to?(:simple_delay_for)).to eq(false)
      expect(@pet.respond_to?(:simple_delay_for)).to eq(false)
    end

    it 'simple_delay_until' do
      expect(ActiveRecord::Base.respond_to?(:simple_delay_until)).to eq(false)
      expect(ApplicationRecord.respond_to?(:simple_delay_until)).to eq(false)

      expect(Owner.respond_to?(:simple_delay_until)).to eq(true)
      expect(@owner.respond_to?(:simple_delay_until)).to eq(true)

      expect(Pet.respond_to?(:simple_delay_until)).to eq(false)
      expect(@pet.respond_to?(:simple_delay_until)).to eq(false)
    end

    it 'simple_delay_spread' do
      expect(ActiveRecord::Base.respond_to?(:simple_delay_spread)).to eq(false)
      expect(ApplicationRecord.respond_to?(:simple_delay_spread)).to eq(false)

      expect(Owner.respond_to?(:simple_delay_spread)).to eq(true)
      expect(@owner.respond_to?(:simple_delay_spread)).to eq(true)

      expect(Pet.respond_to?(:simple_delay_spread)).to eq(false)
      expect(@pet.respond_to?(:simple_delay_spread)).to eq(false)
    end
  end
end
