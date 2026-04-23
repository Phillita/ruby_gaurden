# frozen_string_literal: true

require 'ruby_box'
require 'active_support/concern'
require 'opal'

module RubyBox
  module RuntimeEnvironment
    extend ActiveSupport::Concern

    MAX_CACHE_SIZE = 1000

    included do
      uses 'opal'
      requires 'opal'
    end

    class_methods do
      def compiled_cache
        @compiled_cache ||= {}
      end

      private

      def uses(*gem_names)
        @uses ||= []
        @uses += gem_names
      end

      def requires(*paths)
        @requires ||= []
        @requires += paths
      end

      def executes(source)
        @executes ||= []
        @executes << source
      end

      def snapshot_source
        @snapshot_source ||= begin
          builder = Opal::Builder.new compiler_options: { arity_check: true, dynamic_require_severity: :error }
          inherited_values(:@uses).uniq.each { |g| builder.use_gem g }
          inherited_values(:@requires).uniq.each { |p| builder.build p }
          inherited_values(:@executes).each { |s| builder.build_str s, '(executes)' }

          builder.to_s
        rescue SyntaxError, StandardError => e
          raise CompilationError, e.message
        end
      end

      def inherited_values(ivar)
        ancestors.reverse.flat_map do |ancestor|
          ancestor.instance_variable_defined?(ivar) ? ancestor.instance_variable_get(ivar) : []
        end
      end
    end

    def execute(source)
      js = self.class.compiled_cache[source] || compile_and_cache(source)
      eval_compiled_source(js)
    end

    def compile_and_cache(source)
      # Use the Compiler directly for the execution source to avoid V8 "Genesis" crashes.
      js = Opal::Compiler.new(source, file: '(execute)', arity_check: true).compile

      self.class.compiled_cache.clear if self.class.compiled_cache.size >= MAX_CACHE_SIZE
      self.class.compiled_cache[source] = js
    rescue SyntaxError => e
      raise CompilationError, e.message
    end
  end
end
