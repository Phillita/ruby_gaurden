# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RubyBox do
  it 'has a version number' do
    expect(described_class::VERSION).not_to be_nil
  end

  it 'passes a basic sanity check' do
    expect(described_class.execute('1+1')).to eq(2)
  end

  it 'behaves like the README says', :aggregate_failures do
    stub_const('MySandbox', Class.new(RubyBox::Metal) do
      # Code in the sandbox will block at most one second
      times_out_in(1)

      # Makes the opal gem available for requiring inside the sandbox
      uses 'opal'

      # Requires the Opal compiler inside the sandbox (enables advanced runtime meta-programming like `Kernel#eval`)
      requires 'opal-parser'

      # Exposes the #native_add method to code running inside the sandbox
      exposes :native_add

      # Executes some code in the sandbox to setup it's runtime state
      executes <<-RUBY
        # Some boilerplate code
        class PlayThing
          attr_reader :name

          def initialize(name)
            @name = name
          end

          # Code inside of the sandbox can get a handle on the box with `RubyBox.current` and call exposed methods
          def self.add(a, b)
            RubyBox.current.native_add(a, b)
          end
        end
      RUBY

      def native_add(a, b)
        a + b
      end
    end)

    untrusted_program = <<-RUBY
      $global_state = 'tainted'

      puts "Hello, world"

      car = PlayThing.new("Car")
      car.name
    RUBY

    # Every instance of the sandbox starts with the state configured on the class
    my_sandbox = MySandbox.new
    expect(my_sandbox.execute(untrusted_program)).to eq 'Car'
    expect(my_sandbox.execute('PlayThing.add(2,7)')).to eq 9
    expect(my_sandbox.stdout).to eq(["Hello, world\n"])

    # You can also call top-level methods directly using #call
    my_sandbox.execute('def sum(a, b); a + b; end')
    expect(my_sandbox.call(:sum, 10, 20)).to eq(30)

    # Every instance of the sandbox is isolated
    another_sandbox = MySandbox.new
    expect(another_sandbox.execute('$global_state')).to be_nil

    # It also has an stderr
    another_sandbox.execute('warn "This looks dangerous"')
    expect(another_sandbox.stderr).to eq(["This looks dangerous\n"])

    # Exceptions comes through as subclasses of RubyBox::BoxedError
    expect { another_sandbox.execute('nil.no_method') }.to raise_error(RubyBox::BoxedError)

    # You can determine if you are in a sandbox using `RubyBox.boxed?` and `RubyBox.current`
    expect(described_class).not_to be_boxed
    expect(described_class.current).to be_nil

    # Inheritance
    stub_const('BaseSandbox', Class.new(RubyBox::Metal) do
      executes '$base_initialized = true'
    end)

    stub_const('SpecializedSandbox', Class.new(BaseSandbox) do
      executes '$special_initialized = true'
    end)

    box = SpecializedSandbox.new
    expect(box.execute('$base_initialized')).to be_truthy
    expect(box.execute('$special_initialized')).to be_truthy
  end

  describe 'Caching' do
    let(:sandbox_class) { Class.new(RubyBox::Metal) }

    it 'caches compiled javascript for performance' do
      sandbox = sandbox_class.new
      source = '1 + 2'

      allow(Opal::Compiler).to receive(:new).once.and_call_original
      2.times { sandbox.execute(source) }
      expect(Opal::Compiler).to have_received(:new).once
    end

    it 'evicts entries when MAX_CACHE_SIZE is reached', :aggregate_failures do
      stub_const('RubyBox::RuntimeEnvironment::MAX_CACHE_SIZE', 2)
      sandbox = sandbox_class.new

      sandbox.execute('1')
      sandbox.execute('2')
      expect(sandbox_class.compiled_cache.size).to eq(2)

      sandbox.execute('3')

      # With MAX_CACHE_SIZE 2 and 10% pruning (min 1), the oldest key '1' should be
      # evicted, leaving '2' and '3' in the cache.
      expect(sandbox_class.compiled_cache.size).to eq(2)
      expect(sandbox_class.compiled_cache.keys).to eq(%w[2 3])
    end
  end
end
