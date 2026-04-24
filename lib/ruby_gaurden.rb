# frozen_string_literal: true

require 'ruby_gaurden/version'

module RubyGaurden
  autoload :Bindings, 'ruby_gaurden/bindings'
  autoload :BedError, 'ruby_gaurden/bed_error'
  autoload :Bridging, 'ruby_gaurden/bridging'
  autoload :CompilationError, 'ruby_gaurden/compilation_error'
  autoload :Error, 'ruby_gaurden/error'
  autoload :Execution, 'ruby_gaurden/execution'
  autoload :ExecutionError, 'ruby_gaurden/execution_error'
  autoload :Bed, 'ruby_gaurden/bed'
  autoload :RuntimeEnvironment, 'ruby_gaurden/runtime_environment'
  autoload :ThreadSafety, 'ruby_gaurden/thread_safety'
  autoload :TimeoutError, 'ruby_gaurden/timeout_error'

  module_function

  # Checks if the current execution context is inside a sandbox.
  # @return [Boolean] true if inside a sandbox, false otherwise.
  def planted?
    false
  end

  # Returns the current sandbox proxy instance if running inside a sandbox.
  # @return [Object, nil] The proxy instance or nil if outside a sandbox.
  def current
    nil
  end

  # Convenience method to execute Ruby code in a fresh, one-off sandbox.
  # @param args [Array] Arguments passed to Bed.execute.
  # @return [Object] The result of the execution.
  def execute(...)
    Bed.execute(...)
  end
end
