# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Philiprehberger::Maybe do
  it 'has a version number' do
    expect(described_class::VERSION).not_to be_nil
  end

  describe '.wrap' do
    it 'returns Some for non-nil values' do
      result = described_class.wrap(42)
      expect(result).to be_a(described_class::Some)
      expect(result.value).to eq(42)
    end

    it 'returns None for nil' do
      result = described_class.wrap(nil)
      expect(result).to be_a(described_class::None)
    end

    it 'wraps false as Some' do
      result = described_class.wrap(false)
      expect(result).to be_a(described_class::Some)
      expect(result.value).to eq(false)
    end
  end

  describe Philiprehberger::Maybe::Some do
    subject(:some) { described_class.new(42) }

    it 'is some' do
      expect(some.some?).to be(true)
    end

    it 'is not none' do
      expect(some.none?).to be(false)
    end

    it 'returns the value' do
      expect(some.value).to eq(42)
    end

    describe '#map' do
      it 'transforms the value' do
        result = some.map { |v| v * 2 }
        expect(result.value).to eq(84)
      end

      it 'returns None if block returns nil' do
        result = some.map { |_v| nil }
        expect(result).to be_a(Philiprehberger::Maybe::None)
      end
    end

    describe '#flat_map' do
      it 'returns the Maybe from the block' do
        result = some.flat_map { |v| Philiprehberger::Maybe.wrap(v * 2) }
        expect(result.value).to eq(84)
      end

      it 'raises if block does not return a Maybe' do
        expect { some.flat_map { |v| v * 2 } }.to raise_error(Philiprehberger::Maybe::Error)
      end
    end

    describe '#filter' do
      it 'returns Some when predicate is true' do
        result = some.filter { |v| v > 10 }
        expect(result.value).to eq(42)
      end

      it 'returns None when predicate is false' do
        result = some.filter { |v| v > 100 }
        expect(result).to be_a(Philiprehberger::Maybe::None)
      end
    end

    describe '#or_else' do
      it 'returns self' do
        result = some.or_else(99)
        expect(result.value).to eq(42)
      end
    end

    describe '#or_raise' do
      it 'returns the value' do
        expect(some.or_raise).to eq(42)
      end
    end

    describe '#dig' do
      it 'digs into a hash' do
        some = described_class.new({ a: { b: 1 } })
        result = some.dig(:a, :b)
        expect(result.value).to eq(1)
      end

      it 'returns None for missing keys' do
        some = described_class.new({ a: 1 })
        result = some.dig(:b)
        expect(result).to be_a(Philiprehberger::Maybe::None)
      end

      it 'digs into arrays' do
        some = described_class.new([10, 20, 30])
        result = some.dig(1)
        expect(result.value).to eq(20)
      end
    end

    describe '#deconstruct_keys' do
      it 'returns hash with value and some/none flags' do
        expect(some.deconstruct_keys(nil)).to eq({ value: 42, some: true, none: false })
      end
    end

    describe '#==' do
      it 'is equal to another Some with the same value' do
        expect(some).to eq(described_class.new(42))
      end

      it 'is not equal to a Some with a different value' do
        expect(some).not_to eq(described_class.new(99))
      end
    end

    describe '#inspect' do
      it 'returns a readable representation' do
        expect(some.inspect).to eq('Some(42)')
      end
    end
  end

  describe Philiprehberger::Maybe::None do
    subject(:none) { described_class.instance }

    it 'is not some' do
      expect(none.some?).to be(false)
    end

    it 'is none' do
      expect(none.none?).to be(true)
    end

    it 'returns nil for value' do
      expect(none.value).to be_nil
    end

    describe '#map' do
      it 'returns None' do
        result = none.map { |v| v * 2 }
        expect(result).to be_a(described_class)
      end
    end

    describe '#flat_map' do
      it 'returns None' do
        result = none.flat_map { |v| Philiprehberger::Maybe.wrap(v) }
        expect(result).to be_a(described_class)
      end
    end

    describe '#filter' do
      it 'returns None' do
        result = none.filter { |_v| true }
        expect(result).to be_a(described_class)
      end
    end

    describe '#or_else' do
      it 'returns the default wrapped in Maybe' do
        result = none.or_else(99)
        expect(result.value).to eq(99)
      end

      it 'accepts a block' do
        result = none.or_else { 99 }
        expect(result.value).to eq(99)
      end
    end

    describe '#or_raise' do
      it 'raises the specified error' do
        expect { none.or_raise }.to raise_error(Philiprehberger::Maybe::Error)
      end

      it 'raises a custom error class' do
        expect { none.or_raise(ArgumentError, 'missing') }.to raise_error(ArgumentError, 'missing')
      end
    end

    describe '#dig' do
      it 'returns None' do
        expect(none.dig(:a)).to be_a(described_class)
      end
    end

    describe '#deconstruct_keys' do
      it 'returns hash with nil value and none flag' do
        expect(none.deconstruct_keys(nil)).to eq({ value: nil, some: false, none: true })
      end
    end

    describe '#inspect' do
      it 'returns None' do
        expect(none.inspect).to eq('None')
      end
    end
  end
end
