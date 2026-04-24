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

    x.report('RubyGaurden::Bed (cold start)') do
      # This creates a new bed instance and compiles the code
      RubyGaurden::Bed.new.execute(code)
    end

    x.report('RubyGaurden::Bed (cached)') do
      # This uses a new bed but hits the class-level compilation cache
      RubyGaurden::Bed.new.execute(code)
    end

    x.report('RubyGaurden::Bed (reused bed)') do
      @bed ||= RubyGaurden::Bed.new
      @bed.execute(code)
    end
  end
end

task test: :spec
task default: :test
