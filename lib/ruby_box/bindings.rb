# frozen_string_literal: true

require 'ruby_box'

module RubyBox
  module Bindings
    extend ActiveSupport::Concern

    class_methods do
      def bindings
        @bindings ||= if superclass.respond_to?(:bindings)
                        superclass.bindings.dup
                      else
                        []
                      end
      end

      private

      def binds(target, proc = nil, &block)
        actual_proc = proc || block || -> {}
        bindings << [target, actual_proc]
      end
    end

    def initialize(*)
      super

      self.class.bindings.each do |target, proc|
        bind target, lambda { |*args|
          instance_exec(*args, &proc)
        }
      end
    end

    def bind(target, proc = -> {})
      context.attach(target, proc)
    end
  end
end
