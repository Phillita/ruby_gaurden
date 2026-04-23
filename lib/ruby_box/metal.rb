# frozen_string_literal: true

require 'ruby_box'

module RubyBox
  class Metal
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
