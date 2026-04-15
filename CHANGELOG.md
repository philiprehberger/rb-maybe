# Changelog

All notable changes to this gem will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.2.1] - 2026-04-15

### Changed
- Expand bug report issue template with reproduction code placeholder and required gem version input
- Expand feature request issue template with proposed API code placeholder and alternatives field

## [0.2.0] - 2026-04-03

### Added
- `Some#zip(*others)` to combine multiple Maybes into a single Some of an array
- `Some#tap(&block)` to execute side effects without changing the value
- `None#recover(&block)` to convert None to Some via a recovery block
- `None#zip(*others)` returns None (consistent with Some#zip)
- `None#tap(&block)` no-op returning self
- `Enumerable` support on both Some and None (enables `to_a`, `select`, etc.)
- `Maybe.all?(*maybes)` to check if all arguments are Some
- `Maybe.first_some(*maybes)` to return the first Some or None

## [0.1.7] - 2026-03-31

### Added
- Add GitHub issue templates, dependabot config, and PR template

## [0.1.6] - 2026-03-31

### Changed
- Standardize README badges, support section, and license format

## [0.1.5] - 2026-03-26

### Fixed
- Add Sponsor badge to README
- Fix license section link format

## [0.1.4] - 2026-03-24

### Changed
- Expand test coverage to 50+ examples covering edge cases and error paths

## [0.1.3] - 2026-03-24

### Fixed
- Standardize README code examples to use double-quote require statements

## [0.1.2] - 2026-03-24

### Fixed
- Fix Installation section quote style to double quotes

## [0.1.1] - 2026-03-22

### Changed
- Update rubocop configuration for Windows compatibility

## [0.1.0] - 2026-03-22

### Added
- Initial release
- Maybe.wrap for wrapping values in Some or None
- Some container with map, flat_map, filter, dig, and value extraction
- None container with or_else and or_raise for fallback handling
- Pattern matching support via deconstruct_keys
