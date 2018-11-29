# frozen_string_literal: true

require 'sidekiq_simple_delay/utils'

class UtilsTest
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

      it 'big integer' do
        expect(utils.simple_object?(99_999_999_999_999_999_999)).to eq(true)
      end

      it 'symbol' do
        expect(utils.simple_object?(:things)).to eq(true)
      end

      context 'invalid' do
        it 'non-simple' do
          expect(utils.simple_object?(UtilsTest.new)).to eq(false)
        end

        it 'non-simple - class' do
          expect(utils.simple_object?(UtilsTest)).to eq(false)
        end
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

      context 'invalid' do
        it 'array' do
          expect(utils.simple_object?([2, 'things', UtilsTest.new])).to eq(false)
        end

        it 'hash' do
          arg = {
            'things' => UtilsTest.new
          }
          expect(utils.simple_object?(arg)).to eq(false)
        end
      end
    end
  end
end
