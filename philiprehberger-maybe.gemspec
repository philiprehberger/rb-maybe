# frozen_string_literal: true

require_relative 'lib/philiprehberger/maybe/version'

Gem::Specification.new do |spec|
  spec.name          = 'philiprehberger-maybe'
  spec.version       = Philiprehberger::Maybe::VERSION
  spec.authors       = ['Philip Rehberger']
  spec.email         = ['me@philiprehberger.com']

  spec.summary       = 'Optional/Maybe monad with safe chaining and pattern matching'
  spec.description   = 'A Maybe/Optional type for Ruby providing Some and None containers with safe chaining, ' \
                       'pattern matching via deconstruct_keys, filtering, and value extraction.'
  spec.homepage      = 'https://github.com/philiprehberger/rb-maybe'
  spec.license       = 'MIT'

  spec.required_ruby_version = '>= 3.1.0'

  spec.metadata['homepage_uri']          = spec.homepage
  spec.metadata['source_code_uri']       = spec.homepage
  spec.metadata['changelog_uri']         = "#{spec.homepage}/blob/main/CHANGELOG.md"
  spec.metadata['bug_tracker_uri']       = "#{spec.homepage}/issues"
  spec.metadata['rubygems_mfa_required'] = 'true'

  spec.files = Dir['lib/**/*.rb', 'LICENSE', 'README.md', 'CHANGELOG.md']
  spec.require_paths = ['lib']
end
