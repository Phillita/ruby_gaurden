# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'ruby_gaurden/version'

Gem::Specification.new do |spec|
  spec.name          = 'ruby_gaurden'
  spec.version       = RubyGaurden::VERSION
  spec.authors       = ['Tayler Phillips']
  spec.email         = ['taylerphillips20@gmail.com']

  spec.summary       = 'RubyGaurden allows the execution of untrusted Ruby code safely in a walled garden.'
  spec.homepage      = 'https://github.com/anarchocurious/ruby_gaurden'
  spec.license       = 'MIT'

  spec.files         = Dir['lib/**/*']
  spec.require_paths = %w[lib]

  spec.required_ruby_version = '>= 3.1.0'

  spec.metadata['allowed_push_host'] = 'https://rubygems.org'
  spec.metadata['source_code_uri']   = spec.homepage
  spec.metadata['changelog_uri']     = "#{spec.homepage}/blob/main/CHANGELOG.md"
  spec.metadata['bug_tracker_uri']   = "#{spec.homepage}/issues"

  spec.add_dependency 'activesupport', '>= 7.0'
  spec.add_dependency 'mini_racer', '~> 0.21.0'
  spec.add_dependency 'opal', '1.8.0'
  spec.metadata['rubygems_mfa_required'] = 'true'
end
