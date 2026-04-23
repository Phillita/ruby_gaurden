# frozen_string_literal: true

require 'bundler/gem_tasks'
require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:spec)

desc 'Run console with RubyBox loaded'
task :console do
  require 'pry'
  require 'ruby_box'

  Pry.start
end

desc 'Run benchmarks'
task :benchmark do
  require 'benchmark'
  require 'benchmark/ips'
  require 'ruby_box'

  code = <<-RUBY
    i = 0
    10_000.times { |idx| i += idx }
  RUBY

  # Warm up the cache for the cached report
  RubyBox.execute(code)

  Benchmark.ips do |x|
    x.report('native') do
      i = 0
      10_000.times { |idx| i += idx }
    end

    x.report('boxed (cold start)') do
      # This creates a new sandbox instance and compiles the code
      RubyBox::Metal.new.execute(code)
    end

    x.report('boxed (cached)') do
      # This uses a new sandbox but hits the class-level compilation cache
      RubyBox::Metal.new.execute(code)
    end

    x.report('boxed (reused sandbox)') do
      @sandbox ||= RubyBox::Metal.new
      @sandbox.execute(code)
    end
  end
end

task test: :spec
task default: :test
