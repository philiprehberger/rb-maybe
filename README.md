# philiprehberger-maybe

[![Tests](https://github.com/philiprehberger/rb-maybe/actions/workflows/ci.yml/badge.svg)](https://github.com/philiprehberger/rb-maybe/actions/workflows/ci.yml)
[![Gem Version](https://badge.fury.io/rb/philiprehberger-maybe.svg)](https://rubygems.org/gems/philiprehberger-maybe)
[![Last updated](https://img.shields.io/github/last-commit/philiprehberger/rb-maybe)](https://github.com/philiprehberger/rb-maybe/commits/main)

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

### Combining with Zip

```ruby
a = Philiprehberger::Maybe.wrap(1)
b = Philiprehberger::Maybe.wrap(2)
a.zip(b).value  # => [1, 2]

c = Philiprehberger::Maybe.wrap(nil)
a.zip(c).none?  # => true
```

### Recovery

```ruby
Philiprehberger::Maybe.wrap(nil)
  .recover { 'default' }
  .value  # => 'default'
```

### Side Effects with Tap

```ruby
Philiprehberger::Maybe.wrap(42)
  .tap { |v| puts "Got: #{v}" }
  .map { |v| v * 2 }
  .value  # => 84
```

### Enumerable Support

```ruby
Philiprehberger::Maybe.wrap(42).to_a     # => [42]
Philiprehberger::Maybe.wrap(nil).to_a    # => []

Philiprehberger::Maybe.wrap(5)
  .select { |v| v > 3 }  # => [5]
```

### Utility Methods

```ruby
a = Philiprehberger::Maybe.wrap(1)
b = Philiprehberger::Maybe.wrap(2)
Philiprehberger::Maybe.all?(a, b)        # => true

c = Philiprehberger::Maybe.wrap(nil)
Philiprehberger::Maybe.first_some(c, a)  # => Some(1)
```

### Constructing from Conditions

```ruby
Philiprehberger::Maybe.from_bool(user.admin?, user)
# => Some(user) when admin, None otherwise

Philiprehberger::Maybe.from_bool(cache.valid?) { cache.fetch }
# => Some(value) if the gate passes, None otherwise (block only runs when truthy)

Philiprehberger::Maybe.try { JSON.parse(input) }
# => Some(parsed) on success, None on any StandardError

Philiprehberger::Maybe.try(KeyError) { ENV.fetch('MISSING') }
# => None — only KeyError is caught; other exceptions propagate
```

### Rejecting Values

```ruby
Philiprehberger::Maybe.wrap(user)
  .reject(&:deleted?)
  .value  # => nil when user.deleted?, user otherwise
```

### Flattening Nested Maybes

```ruby
outer = Philiprehberger::Maybe.wrap(Philiprehberger::Maybe.wrap(42))
outer.flatten.value  # => 42
```

## API

### `Maybe`

| Method | Description |
|--------|-------------|
| `.wrap(value)` | Wrap a value in Some (non-nil) or None (nil) |
| `.all?(*maybes)` | Return true if all arguments are Some |
| `.first_some(*maybes)` | Return the first Some, or None if all are None |
| `.from_bool(condition, value = nil, &block)` | Some when condition is truthy (and value/block result is non-nil), else None |
| `.try(*error_classes, &block)` | Run block; return Some on success, None on caught errors or nil (defaults to StandardError) |

### `Maybe::Some`

| Method | Description |
|--------|-------------|
| `#value` | Return the wrapped value |
| `#some?` | Return true |
| `#none?` | Return false |
| `#map { \|v\| }` | Transform the value, returning a new Maybe |
| `#flat_map { \|v\| }` | Transform expecting a Maybe return |
| `#filter { \|v\| }` | Return None if predicate is false |
| `#reject { \|v\| }` | Return None if predicate is true (inverse of filter) |
| `#flatten` | Flatten one level — Some(Some(x)) → Some(x), Some(None) → None |
| `#contains?(value)` | True if the wrapped value equals the argument |
| `#present?` | Return true (alias for `#some?`) |
| `#or_else(default)` | Return self (ignores default) |
| `#or_raise(error, msg)` | Return the value |
| `#dig(*keys)` | Dig into nested hashes/arrays |
| `#zip(*others)` | Combine Maybes; Some array if all Some, else None |
| `#tap { \|v\| }` | Execute block for side effects, return self |
| `#each { \|v\| }` | Yield the value (Enumerable support) |
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
| `#reject { \|v\| }` | Return None (no-op) |
| `#flatten` | Return None (no-op) |
| `#contains?(value)` | Always false |
| `#present?` | Return false (alias for `#some?`) |
| `#or_else(default)` | Return default wrapped in Maybe |
| `#or_raise(error, msg)` | Raise the specified error |
| `#dig(*keys)` | Return None |
| `#recover { }` | Convert None to Some via block |
| `#zip(*others)` | Return None (always) |
| `#tap { \|v\| }` | No-op, return self |
| `#each { \|v\| }` | Yield nothing (Enumerable support) |
| `#deconstruct_keys(keys)` | Pattern matching support |

## Development

```bash
bundle install
bundle exec rspec
bundle exec rubocop
```

## Support

If you find this project useful:

⭐ [Star the repo](https://github.com/philiprehberger/rb-maybe)

🐛 [Report issues](https://github.com/philiprehberger/rb-maybe/issues?q=is%3Aissue+is%3Aopen+label%3Abug)

💡 [Suggest features](https://github.com/philiprehberger/rb-maybe/issues?q=is%3Aissue+is%3Aopen+label%3Aenhancement)

❤️ [Sponsor development](https://github.com/sponsors/philiprehberger)

🌐 [All Open Source Projects](https://philiprehberger.com/open-source-packages)

💻 [GitHub Profile](https://github.com/philiprehberger)

🔗 [LinkedIn Profile](https://www.linkedin.com/in/philiprehberger)

## License

[MIT](LICENSE)
