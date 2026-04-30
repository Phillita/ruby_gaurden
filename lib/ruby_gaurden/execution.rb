# frozen_string_literal: true

require 'ruby_gaurden'
require 'active_support/concern'
require 'mini_racer'

module RubyGaurden
  module Execution
    extend ActiveSupport::Concern

    DEFAULT_MAXIMUM_EXECUTION_TIME = 1000
    DEFAULT_MAX_MEMORY = 512 * 1024 * 1024 # 512MB default limit

    class_methods do
      def maximum_execution_time
        @maximum_execution_time ||= superclass.maximum_execution_time if superclass.respond_to?(:maximum_execution_time)
      end

      def maximum_memory
        @maximum_memory ||= superclass.maximum_memory if superclass.respond_to?(:maximum_memory)
      end

      # Sets the maximum time a script can execute before being terminated.
      # @param seconds [Integer, Float] Time in seconds.
      def times_out_in(seconds)
        @maximum_execution_time = seconds
      end

      # Sets the maximum memory the V8 context can consume.
      # @param bytes [Integer] Memory limit in bytes.
      def limits_memory_to(bytes)
        @maximum_memory = bytes
      end

      # Accesses the thread-safe pool of pre-warmed V8 contexts.
      # @return [Thread::Queue]
      def context_pool
        @context_pool ||= ::Queue.new
      end

      # Pre-warms a specified number of V8 contexts and adds them to the pool.
      # @param size [Integer] The number of contexts to create.
      def warm_up(size = 1)
        size.times { context_pool.push(create_context) }
      end

      # Creates a fresh V8 context and evaluates the initialization source.
      # Use this to bypass the pool if needed or to manually populate it.
      # @return [MiniRacer::Context]
      def create_context
        # Use a large timeout (30s) for initialization to ensure the large Opal
        # runtime loads even if the user set a small timeout for their code.
        MiniRacer::Context.new(
          timeout: (maximum_execution_time || DEFAULT_MAXIMUM_EXECUTION_TIME) * 1000,
          max_memory: maximum_memory || DEFAULT_MAX_MEMORY
        ).tap do |ctx|
          # We use a secondary timeout for the init phase. If this fails,
          # the context is not returned/tapped, preventing a "broken"
          # context from entering the pool or being used by an instance.
          ctx.eval(send(:initialization_source), timeout: 30_000)
        end
      end
    end

    def maximum_execution_time
      @maximum_execution_time ||= self.class.maximum_execution_time
    end

    def maximum_memory
      @maximum_memory ||= self.class.maximum_memory
    end

    def maximum_execution_time_ms
      return unless maximum_execution_time

      maximum_execution_time * 1000
    end

    def context
      @context ||= checkout_context
    end

    private

    def checkout_context
      self.class.context_pool.pop(true)
    rescue ThreadError
      self.class.create_context
    end

    def eval_compiled_source(source)
      context.eval source
    rescue MiniRacer::RuntimeError => e
      raise ExecutionError, e.message
    rescue MiniRacer::ScriptTerminatedError => e
      raise TimeoutError, e.message
    end
  end
end
