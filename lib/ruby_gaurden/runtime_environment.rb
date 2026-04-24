# frozen_string_literal: true

require 'ruby_gaurden'
require 'active_support/concern'
require 'opal'

module RubyGaurden
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

      # Declares a gem dependency to be loaded into the sandbox.
      # @param gem_names [Array<String>] List of gem names.
      def uses(*gem_names)
        @uses ||= []
        @uses += gem_names
      end

      # Declares a file or feature to be required within the sandbox.
      # @param paths [Array<String>] List of paths to require.
      def requires(*paths)
        @requires ||= []
        @requires += paths
      end

      # Defines Ruby code to be executed during the initialization of every sandbox instance.
      # Useful for setting up global state or helper classes.
      # @param source [String] The Ruby code to execute during boot.
      def executes(source)
        @executes ||= []
        @executes << source
      end

      def initialization_source
        @initialization_source ||= begin
          builder = Opal::Builder.new compiler_options: { arity_check: true, dynamic_require_severity: :error }
          builder.build 'opal'

          # Ensure the builder can resolve requirements by including the gems
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

    # Executes a string of Ruby code within the sandbox instance.
    # Results are cached by the source string to optimize repeated calls.
    # @param source [String] The Ruby code to execute.
    # @return [Object] The result of the execution, translated to host Ruby objects.
    # @raise [CompilationError] if the code has syntax errors.
    # @raise [ExecutionError] if the code raises an exception during runtime.
    def execute(source)
      js = self.class.compiled_cache[source] || compile_and_cache(source)
      eval_compiled_source(js)
    end

    # Compiles Ruby source to JavaScript and clears the cache if the limit is reached.
    # @param source [String] Ruby source code.
    # @return [String] Compiled JavaScript.
    def compile_and_cache(source)
      # Use the Compiler directly for the execution source to avoid V8 "Genesis" crashes.
      js = Opal::Compiler.new(source, file: '(execute)', arity_check: true).compile

      if self.class.compiled_cache.size >= MAX_CACHE_SIZE
        # Prune the oldest 10% of entries (at least 1) to avoid performance cliffs.
        # Since Ruby Hashes maintain insertion order, this behaves like FIFO.
        amount_to_prune = [1, MAX_CACHE_SIZE / 10].max
        keys_to_purge = self.class.compiled_cache.keys.first(amount_to_prune)
        keys_to_purge.each { |k| self.class.compiled_cache.delete(k) }
      end
      self.class.compiled_cache[source] = js
    rescue SyntaxError => e
      raise CompilationError, e.message
    end
  end
end
