# frozen_string_literal: true

require 'ruby_box'
require 'active_support/concern'
require 'mini_racer'

module RubyBox
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

      private

      def snapshot_source
        raise NotImplementedError
      end

      def times_out_in(seconds)
        @maximum_execution_time = seconds
      end

      def limits_memory_to(bytes)
        @maximum_memory = bytes
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
      @context ||= begin
        ctx = MiniRacer::Context.new(
          timeout: maximum_execution_time_ms || DEFAULT_MAXIMUM_EXECUTION_TIME,
          max_memory: maximum_memory || DEFAULT_MAX_MEMORY
        )
        ctx.eval self.class.send(:snapshot_source)
        ctx
      end
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
