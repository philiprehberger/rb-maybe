# philiprehberger-maybe

[![Tests](https://github.com/philiprehberger/rb-maybe/actions/workflows/ci.yml/badge.svg)](https://github.com/philiprehberger/rb-maybe/actions/workflows/ci.yml)
[![Gem Version](https://badge.fury.io/rb/philiprehberger-maybe.svg)](https://rubygems.org/gems/philiprehberger-maybe)
[![License](https://img.shields.io/github/license/philiprehberger/rb-maybe)](LICENSE)
[![Sponsor](https://img.shields.io/badge/sponsor-GitHub%20Sponsors-ec6cb9)](https://github.com/sponsors/philiprehberger)

Optional/Maybe monad with safe chaining and pattern matching

## Requirements

- Ruby >= 3.1

## Installation

Add to your Gemfile:

```ruby
gem "philiprehberger-maybe"
```

Or install directly:

```bash
gem install philiprehberger-maybe
```

## Usage

```ruby
require "philiprehberger/maybe"

result = Philiprehberger::Maybe.wrap(42)
result.value  # => 42
result.some?  # => true

none = Philiprehberger::Maybe.wrap(nil)
none.none?  # => true
```

### Safe Chaining

```ruby
result = Philiprehberger::Maybe.wrap(user)
  .map { |u| u.address }
  .map { |a| a.city }
  .or_else('Unknown')
```

### Pattern Matching

```ruby
case Philiprehberger::Maybe.wrap(value)
in { some: true, value: Integer => v }
  puts "Got integer: #{v}"
in { none: true }
  puts 'No value'
end
```

### Filtering

```ruby
Philiprehberger::Maybe.wrap(18)
  .filter { |v| v >= 21 }
  .or_else(0)
  .value  # => 0
```

### Digging into Nested Structures

```ruby
data = { user: { address: { city: 'Vienna' } } }
Philiprehberger::Maybe.wrap(data)
  .dig(:user, :address, :city)
  .value  # => 'Vienna'
```

### Flat Map

```ruby
Philiprehberger::Maybe.wrap(5)
  .flat_map { |v| Philiprehberger::Maybe.wrap(v > 0 ? v : nil) }
  .value  # => 5
```

## API

### `Maybe`

| Method | Description |
|--------|-------------|
| `.wrap(value)` | Wrap a value in Some (non-nil) or None (nil) |

### `Maybe::Some`

| Method | Description |
|--------|-------------|
| `#value` | Return the wrapped value |
| `#some?` | Return true |
| `#none?` | Return false |
| `#map { \|v\| }` | Transform the value, returning a new Maybe |
| `#flat_map { \|v\| }` | Transform expecting a Maybe return |
| `#filter { \|v\| }` | Return None if predicate is false |
| `#or_else(default)` | Return self (ignores default) |
| `#or_raise(error, msg)` | Return the value |
| `#dig(*keys)` | Dig into nested hashes/arrays |
| `#deconstruct_keys(keys)` | Pattern matching support |

### `Maybe::None`

| Method | Description |
|--------|-------------|
| `#value` | Return nil |
| `#some?` | Return false |
| `#none?` | Return true |
| `#map { \|v\| }` | Return None (no-op) |
| `#flat_map { \|v\| }` | Return None (no-op) |
| `#filter { \|v\| }` | Return None (no-op) |
| `#or_else(default)` | Return default wrapped in Maybe |
| `#or_raise(error, msg)` | Raise the specified error |
| `#dig(*keys)` | Return None |
| `#deconstruct_keys(keys)` | Pattern matching support |

## Development

```bash
bundle install
bundle exec rspec
bundle exec rubocop
```

## License

[MIT](LICENSE)
