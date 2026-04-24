# frozen_string_literal: true

require 'ruby_gaurden'
require 'json'
require 'active_support/concern'

module RubyGaurden
  module Bridging
    extend ActiveSupport::Concern

    included do
      binds('__rb_exit') { |status| raise Error, "Exit with status #{status.inspect}" }
      binds('__rb_stdout_write') { |data| stdout << data }
      binds('__rb_stderr_write') { |data| stderr << data }

      executes <<-RUBY
        # backtick_javascript: true
        require 'native'
        require 'singleton'
        require 'json'

        module RubyGaurden
          VERSION = #{VERSION.inspect}

          class CurrentBedProxy
            include Singleton
          end

          def self.planted?
            true
          end

          def self.current
            CurrentBedProxy.instance
          end

          # Handles method invocation from the host, ensuring data is correctly
          # translated and errors are caught.
          def self.__invoke_from_host(method_name, args_json)
            args = JSON.parse(args_json)
            value = ::Object.send(method_name, *args)

            { isCaught: false, val: value.to_json }
          rescue Exception => e
            { isCaught: true, val: [e.class.name, e.message].to_json }
          end

          # Handles code evaluation from the host.
          def self.__eval_from_host(js_source)
            value = `eval(js_source)`
            { isCaught: false, val: value.to_json }
          rescue Exception => e
            { isCaught: true, val: [e.class.name, e.message].to_json }
          end
        end

        module Kernel
          def exit(status = 0)
            `__rb_exit(status)`
          end
        end

        $stdout.write_proc = ->(data) { `__rb_stdout_write(data)` }
        $stderr.write_proc = ->(data) { `__rb_stderr_write(data)` }

        `
          globalThis.__rb_bridge_invoke = function(methodName, argsJson) {
            return Opal.RubyGaurden.$__invoke_from_host(methodName, argsJson).$to_n();
          };

          globalThis.__rb_eval_wrapper = function(source) {
            return Opal.RubyGaurden.$__eval_from_host(source).$to_n();
          };
        `
      RUBY
    end

    class_methods do
      def exposes(*method_names)
        method_names.each do |method_name|
          handle = "__rb_expose_#{method_name}"
          binds(handle, ->(json) { send(method_name, *JSON.parse(json)).to_json })

          executes(<<-RUBY)
            # backtick_javascript: true
            def (RubyGaurden::CurrentBedProxy.instance).#{method_name}(*args, &block)
              raise ArgumentError, "Blocks not supported" if block
              JSON.parse(`#{handle}(\#{args.to_json})`)
            end
          RUBY
        end
      end
    end

    def stdout
      @stdout ||= []
    end

    def stderr
      @stderr ||= []
    end

    def reset_io!
      @stdout = []
      @stderr = []
    end

    def call(method_name, *args)
      # We use JSON to move data across the bridge to avoid V8/Ruby object mapping overhead
      # and to ensure Opal objects are correctly initialized.
      serialized_args = args.to_json
      result = context.call('__rb_bridge_invoke', method_name.to_s, serialized_args)
      handle_bridge_result(result)
    end

    private

    def eval_compiled_source(source)
      result = context.call('__rb_eval_wrapper', source)
      handle_bridge_result(result) # result is the Ruby Hash returned by MiniRacer
    rescue MiniRacer::ScriptTerminatedError => e
      raise TimeoutError, e.message
    rescue MiniRacer::RuntimeError, StandardError => e
      raise e if e.is_a?(RubyGaurden::Error)

      raise ExecutionError, e.message
    end

    def handle_bridge_result(result)
      return unless result.is_a?(Hash)

      if result.fetch('isCaught', false)
        class_name, message = result_value(result)
        raise BedError[class_name], message
      end

      result_value(result)
    rescue MiniRacer::RuntimeError, StandardError => e
      raise e if e.is_a?(RubyGaurden::Error)

      raise ExecutionError, e.message
    end

    def result_value(result)
      result['val'] ? JSON.parse(result['val'], quirks_mode: true) : nil
    end
  end
end
