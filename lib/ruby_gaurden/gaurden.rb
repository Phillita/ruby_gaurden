# frozen_string_literal: true

require 'ruby_gaurden'

module RubyGaurden
  class Bed
    include Execution
    include RuntimeEnvironment
    include Bindings
    include Bridging
    include ThreadSafety

    def self.execute(...)
      new.execute(...)
    end
  end
end
