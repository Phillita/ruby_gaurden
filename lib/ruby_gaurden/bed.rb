# frozen_string_literal: true

require 'ruby_gaurden'

module RubyGaurden
  class Bed
    include Execution
    include RuntimeEnvironment
    include Bindings
    include Bridging
    include ThreadSafety

    # Creates a new instance of the Bed and executes the provided source.
    # @param args [Array] Arguments passed to #execute.
    # @return [Object] The result of the execution.
    # @see #execute
    def self.execute(...)
      new.execute(...)
    end
  end
end
