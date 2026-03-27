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
        result = some[:b]
        expect(result).to be_a(Philiprehberger::Maybe::None)
      end

      it 'digs into arrays' do
        some = described_class.new([10, 20, 30])
        result = some[1]
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

    describe '#to_s' do
      it 'is aliased to inspect' do
        expect(some.to_s).to eq('Some(42)')
      end
    end

    describe '#==' do
      it 'is not equal to a non-Some object' do
        expect(some).not_to eq(42)
      end

      it 'is not equal to None' do
        expect(some).not_to eq(Philiprehberger::Maybe::None.instance)
      end
    end

    describe '#map chaining' do
      it 'supports chained map calls' do
        result = some.map { |v| v + 8 }.map { |v| v * 2 }
        expect(result.value).to eq(100)
      end

      it 'short-circuits to None on nil in chain' do
        result = some.map { |_v| nil }.map { |v| v * 2 }
        expect(result).to be_a(Philiprehberger::Maybe::None)
      end
    end

    describe '#flat_map' do
      it 'returns None when block returns None' do
        result = some.flat_map { |_v| Philiprehberger::Maybe::None.instance }
        expect(result).to be_a(Philiprehberger::Maybe::None)
      end

      it 'includes a descriptive error message' do
        expect { some.flat_map { |v| v * 2 } }.to raise_error(
          Philiprehberger::Maybe::Error, 'flat_map block must return a Maybe'
        )
      end
    end

    describe '#or_else' do
      it 'ignores the default and returns self' do
        result = some.or_else(99)
        expect(result).to be(some)
      end
    end

    describe '#or_raise' do
      it 'returns value even with a custom error class' do
        expect(some.or_raise(ArgumentError, 'missing')).to eq(42)
      end
    end

    describe '#dig' do
      it 'returns None for non-diggable values' do
        some = described_class.new('hello')
        result = some[:length]
        expect(result).to be_a(Philiprehberger::Maybe::None)
      end

      it 'digs into mixed hash and array nesting' do
        some = described_class.new({ users: [{ name: 'Alice' }] })
        result = some.dig(:users, 0, :name)
        expect(result.value).to eq('Alice')
      end

      it 'returns None for out-of-bounds array index' do
        some = described_class.new([1, 2, 3])
        result = some[10]
        expect(result).to be_a(Philiprehberger::Maybe::None)
      end

      it 'handles single key dig into hash' do
        some = described_class.new({ x: 99 })
        result = some[:x]
        expect(result.value).to eq(99)
      end
    end

    describe '#filter' do
      it 'returns self (same object) when predicate is true' do
        result = some.filter { |v| v == 42 }
        expect(result).to be(some)
      end
    end

    context 'with false value' do
      subject(:some_false) { described_class.new(false) }

      it 'maps over false' do
        result = some_false.map(&:!)
        expect(result.value).to eq(true)
      end

      it 'retains false through filter' do
        result = some_false.filter { |_v| true }
        expect(result.value).to eq(false)
      end
    end

    context 'with empty string' do
      it 'wraps empty string as Some' do
        result = Philiprehberger::Maybe.wrap('')
        expect(result).to be_a(described_class)
        expect(result.value).to eq('')
      end
    end

    context 'with zero' do
      it 'wraps zero as Some' do
        result = Philiprehberger::Maybe.wrap(0)
        expect(result).to be_a(described_class)
        expect(result.value).to eq(0)
      end
    end

    context 'with empty collections' do
      it 'wraps empty array as Some' do
        result = Philiprehberger::Maybe.wrap([])
        expect(result).to be_a(described_class)
        expect(result.value).to eq([])
      end

      it 'wraps empty hash as Some' do
        result = Philiprehberger::Maybe.wrap({})
        expect(result).to be_a(described_class)
        expect(result.value).to eq({})
      end
    end

    describe 'pattern matching' do
      it 'matches Some with in pattern' do
        result = case some
                 in { some: true, value: Integer => v }
                   v
                 end
        expect(result).to eq(42)
      end
    end

    describe 'chained operations' do
      it 'chains map, filter, and or_else' do
        result = described_class.new(5)
                                .map { |v| v * 10 }
                                .filter { |v| v > 100 }
                                .or_else(0)
        expect(result.value).to eq(0)
      end

      it 'chains map and flat_map' do
        result = described_class.new(3)
                                .map { |v| v + 1 }
                                .flat_map { |v| Philiprehberger::Maybe.wrap(v * 2) }
        expect(result.value).to eq(8)
      end

      it 'chains flat_map, filter, and or_else through None path' do
        result = described_class.new(10)
                                .flat_map { |_v| Philiprehberger::Maybe::None.instance }
                                .filter { |_v| true }
                                .or_else(0)
        expect(result.value).to eq(0)
      end

      it 'chains map, flat_map, and dig into nested data' do
        result = described_class.new({ users: [{ name: 'Bob' }] })
                                .dig(:users, 0)
                                .map { |user| user[:name] }
                                .flat_map { |name| Philiprehberger::Maybe.wrap(name.upcase) }
        expect(result.value).to eq('BOB')
      end
    end

    describe '#inspect' do
      it 'represents string values with quotes' do
        expect(described_class.new('hello').inspect).to eq('Some("hello")')
      end

      it 'represents array values' do
        expect(described_class.new([1, 2]).inspect).to eq('Some([1, 2])')
      end

      it 'represents hash values' do
        expect(described_class.new({ a: 1 }).inspect).to eq("Some(#{({ a: 1 }).inspect})")
      end

      it 'represents nil-containing Some (via new, not wrap)' do
        some_nil = described_class.new(nil)
        expect(some_nil.inspect).to eq('Some(nil)')
      end

      it 'represents symbol values' do
        expect(described_class.new(:foo).inspect).to eq('Some(:foo)')
      end
    end

    describe '#to_s' do
      it 'matches inspect for string values' do
        s = described_class.new('test')
        expect(s.to_s).to eq(s.inspect)
      end
    end

    describe '#map' do
      it 'returns a Some when block returns a non-nil value' do
        result = some.map(&:to_s)
        expect(result).to be_a(described_class)
        expect(result.value).to eq('42')
      end
    end

    describe '#flat_map' do
      it 'accepts a block returning Some directly' do
        result = some.flat_map { |v| described_class.new(v + 1) }
        expect(result).to be_a(described_class)
        expect(result.value).to eq(43)
      end
    end

    describe '#dig' do
      it 'returns Some wrapping the value for zero keys' do
        some = described_class.new(42)
        result = some.dig
        expect(result).to be_a(described_class)
        expect(result.value).to eq(42)
      end

      it 'returns None when intermediate nested value is nil' do
        some = described_class.new({ a: { b: nil } })
        result = some.dig(:a, :b, :c)
        expect(result).to be_a(Philiprehberger::Maybe::None)
      end

      it 'returns None for deeply nested missing key' do
        some = described_class.new({ a: { b: { c: 1 } } })
        result = some.dig(:a, :b, :d)
        expect(result).to be_a(Philiprehberger::Maybe::None)
      end

      it 'handles array of arrays' do
        some = described_class.new([[10, 20], [30, 40]])
        result = some.dig(1, 0)
        expect(result.value).to eq(30)
      end

      it 'returns None when array contains nil at index' do
        some = described_class.new([nil, 2])
        result = some[0]
        expect(result).to be_a(Philiprehberger::Maybe::None)
      end
    end

    describe '#==' do
      it 'is not equal to a None instance' do
        expect(described_class.new(nil)).not_to eq(Philiprehberger::Maybe::None.instance)
      end

      it 'compares by value, not object identity' do
        a = described_class.new('hello')
        b = described_class.new('hello')
        expect(a).to eq(b)
        expect(a).not_to be(b)
      end
    end

    context 'wrapping a Maybe inside a Maybe' do
      it 'wraps Some inside Some' do
        inner = described_class.new(1)
        outer = Philiprehberger::Maybe.wrap(inner)
        expect(outer).to be_a(described_class)
        expect(outer.value).to be(inner)
      end
    end

    context 'with symbol value' do
      subject(:some_sym) { described_class.new(:active) }

      it 'maps over a symbol' do
        result = some_sym.map(&:to_s)
        expect(result.value).to eq('active')
      end

      it 'filters a symbol value' do
        result = some_sym.filter { |v| v == :active }
        expect(result.value).to eq(:active)
      end
    end

    describe 'pattern matching' do
      it 'distinguishes Some from None in a case expression' do
        values = [described_class.new(1), Philiprehberger::Maybe::None.instance, described_class.new(2)]
        results = values.map do |maybe|
          case maybe
          in { some: true, value: v }
            v
          in { none: true }
            :none
          end
        end
        expect(results).to eq([1, :none, 2])
      end

      it 'extracts string value via pattern matching' do
        s = described_class.new('hello')
        result = case s
                 in { some: true, value: String => v }
                   v.upcase
                 end
        expect(result).to eq('HELLO')
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
        expect(none[:a]).to be_a(described_class)
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

    describe '#to_s' do
      it 'is aliased to inspect' do
        expect(none.to_s).to eq('None')
      end
    end

    describe '#==' do
      it 'is equal to itself' do
        expect(none).to eq(described_class.instance)
      end

      it 'is not equal to a non-None object' do
        expect(none).not_to eq(nil)
      end

      it 'is not equal to Some' do
        expect(none).not_to eq(Philiprehberger::Maybe::Some.new(nil))
      end
    end

    describe '#or_else' do
      it 'returns None when default is nil' do
        result = none.or_else(nil)
        expect(result).to be_a(described_class)
      end

      it 'uses block over argument when both provided' do
        result = none.or_else(1) { 2 }
        expect(result.value).to eq(2)
      end
    end

    describe '#or_raise' do
      it 'raises with default message' do
        expect { none.or_raise }.to raise_error(Philiprehberger::Maybe::Error, 'value is absent')
      end
    end

    describe '#dig' do
      it 'returns None regardless of number of keys' do
        expect(none.dig(:a, :b, :c)).to be_a(described_class)
      end

      it 'returns None with no keys' do
        expect(none.dig).to be_a(described_class)
      end
    end

    it 'is a singleton' do
      expect(described_class.instance).to be(described_class.instance)
    end

    describe '#map' do
      it 'does not call the block' do
        called = false
        none.map { called = true }
        expect(called).to be(false)
      end

      it 'returns the same None instance' do
        expect(none.map { |v| v }).to be(none)
      end
    end

    describe '#flat_map' do
      it 'does not call the block' do
        called = false
        none.flat_map { called = true }
        expect(called).to be(false)
      end

      it 'returns the same None instance' do
        expect(none.flat_map { |v| v }).to be(none)
      end
    end

    describe '#filter' do
      it 'does not call the block' do
        called = false
        none.filter { called = true }
        expect(called).to be(false)
      end

      it 'returns the same None instance' do
        expect(none.filter { |_v| true }).to be(none)
      end
    end

    describe '#or_else' do
      it 'returns None when block returns nil' do
        result = none.or_else { nil }
        expect(result).to be_a(described_class)
        expect(result.value).to be_nil
      end

      it 'wraps false as Some' do
        result = none.or_else(false)
        expect(result).to be_a(Philiprehberger::Maybe::Some)
        expect(result.value).to eq(false)
      end
    end

    describe '#or_raise' do
      it 'raises with custom error class only (default message)' do
        expect { none.or_raise(RuntimeError) }.to raise_error(RuntimeError, 'value is absent')
      end
    end

    describe 'pattern matching' do
      it 'matches None with in pattern' do
        result = case none
                 in { none: true, value: nil }
                   :matched
                 end
        expect(result).to eq(:matched)
      end

      it 'does not match Some pattern' do
        result = case none
                 in { some: true }
                   :some
                 in { none: true }
                   :none
                 end
        expect(result).to eq(:none)
      end
    end
  end

  describe Philiprehberger::Maybe::Error do
    it 'is a subclass of StandardError' do
      expect(described_class).to be < StandardError
    end

    it 'can be instantiated with a message' do
      error = described_class.new('test error')
      expect(error.message).to eq('test error')
    end
  end
end
