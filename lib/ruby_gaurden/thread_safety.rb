# frozen_string_literal: true

require 'ruby_gaurden'
require 'active_support/concern'
require 'monitor'

module RubyGaurden
  module ThreadSafety
    extend ActiveSupport::Concern

    class_methods do
      def maximum_execution_time
        synchronize { super }
      end

      def initialization_source
        synchronize { super }
      end

      def bindings
        synchronize { super }
      end

      private

      def times_out_in(...)
        synchronize { super }
      end

      def uses(...)
        synchronize { super }
      end

      def requires(...)
        synchronize { super }
      end

      def executes(...)
        synchronize { super }
      end

      def binds(...)
        synchronize { super }
      end

      def exposes(...)
        synchronize { super }
      end

      def synchronize(&)
        monitor.synchronize(&)
      end

      def monitor
        @monitor ||= Monitor.new
      end
    end

    def maximum_execution_time
      synchronize { super }
    end

    def execute(...)
      synchronize { super }
    end

    def synchronize(&)
      monitor.synchronize(&)
    end

    def monitor
      @monitor ||= Monitor.new
    end
  end
end
