# frozen_string_literal: true

require 'bundler/gem_tasks'
require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:spec)

desc 'Run console with RubyGaurden loaded'
task :console do
  require 'pry'
  require 'ruby_gaurden'

  Pry.start
end

desc 'Run benchmarks'
task :benchmark do
  require 'benchmark'
  require 'benchmark/ips'
  require 'ruby_gaurden'

  code = <<-RUBY
    i = 0
    10_000.times { |idx| i += idx }
  RUBY

  # Warm up the cache for the cached report
  RubyGaurden.execute(code)

  Benchmark.ips do |x|
    x.report('native') do
      i = 0
      10_000.times { |idx| i += idx }
    end

    x.report('gaurden (cold start)') do
      # This creates a new gaurden instance and compiles the code
      RubyGaurden::Gaurden.new.execute(code)
    end

    x.report('gaurden (cached)') do
      # This uses a new gaurden but hits the class-level compilation cache
      RubyGaurden::Gaurden.new.execute(code)
    end

    x.report('gaurden (reused gaurden)') do
      @gaurden ||= RubyGaurden::Gaurden.new
      @gaurden.execute(code)
    end
  end
end

task test: :spec
task default: :test
