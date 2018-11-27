# frozen_string_literal: true

class User
end

class ComplexUser
  def initialize(subs)
    @subs = subs
  end

  def each
    @subs.each { |s| yield s }
  end
end

RSpec.describe SidekiqSimpleDelay::Utils do
  let(:utils) { SidekiqSimpleDelay::Utils }

  context 'system types' do
    context 'simple' do
      it 'nil' do
        expect(utils.simple_object?(nil)).to eq(true)
      end

      it 'true' do
        expect(utils.simple_object?(true)).to eq(true)
      end

      it 'false' do
        expect(utils.simple_object?(false)).to eq(true)
      end

      it 'string' do
        expect(utils.simple_object?('things')).to eq(true)
      end

      it 'float' do
        expect(utils.simple_object?(1.23)).to eq(true)
      end

      it 'integer' do
        expect(utils.simple_object?(123)).to eq(true)
      end

      it 'symbol' do
        expect(utils.simple_object?(:things)).to eq(true)
      end
    end

    context 'complex' do
      it 'array' do
        expect(utils.simple_object?([:things, 1234])).to eq(true)
      end

      it 'hash' do
        hash = { things: 1234, 23 => 'things' }
        expect(utils.simple_object?(hash)).to eq(true)
      end
    end
  end

  context 'user objects' do
    before(:each) do
      %i[
        user_simple_objects
        simple_complex_objects
      ].each do |ivar|
        str = "@#{ivar}"

        next unless utils.instance_variable_defined?(str)

        utils.remove_instance_variable(str)
      end
    end

    it 'rejects User' do
      expect(utils.simple_object?(User.new)).to eq(false)
    end

    it 'accepts User' do
      utils.register_simple_object(User)

      expect(utils.simple_object?(User.new)).to eq(true)
    end

    it 'accepts ComplexUser' do
      utils.register_simple_object(ComplexUser)
      user = ComplexUser.new([:things, 1])

      expect(utils.simple_object?(user)).to eq(true)
    end

    it 'rejects ComplexUser with User sub' do
      utils.register_simple_object(ComplexUser)
      user = ComplexUser.new([User.new, 1])

      expect(utils.simple_object?(user)).to eq(false)
    end

    it 'rejects ComplexUser' do
      expect(utils.simple_object?(User.new)).to eq(false)
    end

    it 'accepts ComplexUser with User sub' do
      utils.register_simple_object(ComplexUser)
      utils.register_simple_object(User)
      user = ComplexUser.new([User.new, 1])

      expect(utils.simple_object?(user)).to eq(true)
    end
  end
end
