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
  autoload :Bed, 'ruby_gaurden/gaurden'
  autoload :RuntimeEnvironment, 'ruby_gaurden/runtime_environment'
  autoload :ThreadSafety, 'ruby_gaurden/thread_safety'
  autoload :TimeoutError, 'ruby_gaurden/timeout_error'

  module_function

  def planted?
    false
  end

  def current
    nil
  end

  def execute(...)
    Bed.execute(...)
  end
end
