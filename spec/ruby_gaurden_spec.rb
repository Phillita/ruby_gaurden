# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RubyGaurden do
  it 'has a version number' do
    expect(described_class::VERSION).not_to be_nil
  end

  it 'passes a basic sanity check' do
    expect(described_class.execute('1+1')).to eq(2)
  end

  describe 'README examples' do
    let(:sandbox_class) do
      stub_const('MySandbox', Class.new(RubyGaurden::Bed) do
        times_out_in(1)
        uses 'opal'
        requires 'opal-parser'
        exposes :native_add

        executes <<-RUBY
          class PlayThing
            attr_reader :name
            def initialize(n); @name = n; end
            def self.add(left, right); RubyGaurden.current.native_add(left, right); end
          end
        RUBY

        def native_add(left, right) = left + right
      end)
    end

    let(:my_sandbox) { sandbox_class.new }

    let(:untrusted_program) do
      <<-RUBY
        $global_state = 'tainted'
        puts "Hello, world"
        car = PlayThing.new("Car")
        car.name
      RUBY
    end

    it 'initializes state and executes code', :aggregate_failures do
      expect(my_sandbox.execute(untrusted_program)).to eq 'Car'
      expect(my_sandbox.execute('PlayThing.add(2,7)')).to eq 9
      expect(my_sandbox.stdout).to eq(["Hello, world\n"])
    end

    it 'supports direct method calls via #call' do
      my_sandbox.execute('def sum(a, b); a + b; end')
      expect(my_sandbox.call(:sum, 10, 20)).to eq(30)
    end

    it 'ensures every instance is isolated' do
      another_sandbox = sandbox_class.new
      expect(another_sandbox.execute('$global_state')).to be_nil
    end

    it 'captures stderr' do
      my_sandbox.execute('warn "This looks dangerous"')
      expect(my_sandbox.stderr).to eq(["This looks dangerous\n"])
    end

    it 'translates exceptions to BedError' do
      expect { my_sandbox.execute('nil.no_method') }.to raise_error(RubyGaurden::BedError)
    end

    it { expect(described_class).not_to be_planted }
    it { expect(described_class.current).to be_nil }
  end

  describe 'Inheritance' do
    let(:base_bed) do
      stub_const('BaseBed', Class.new(RubyGaurden::Bed) do
        executes '$base_initialized = true'
      end)
    end

    let(:specialized_bed_class) do
      stub_const('SpecializedBed', Class.new(base_bed) do
        executes '$special_initialized = true'
      end)
    end

    it 'inherits configuration from parent beds', :aggregate_failures do
      bed = specialized_bed_class.new
      expect(bed.execute('$base_initialized')).to be_truthy
      expect(bed.execute('$special_initialized')).to be_truthy
    end
  end

  describe 'Caching' do
    let(:sandbox_class) { Class.new(RubyGaurden::Bed) }

    it 'caches compiled javascript for performance' do
      sandbox = sandbox_class.new
      source = '1 + 2'

      allow(Opal::Compiler).to receive(:new).once.and_call_original
      2.times { sandbox.execute(source) }
      expect(Opal::Compiler).to have_received(:new).once
    end

    context 'when MAX_CACHE_SIZE is reached' do
      let(:sandbox) { sandbox_class.new }

      before do
        stub_const('RubyGaurden::RuntimeEnvironment::MAX_CACHE_SIZE', 2)
        sandbox.execute('1')
        sandbox.execute('2')
      end

      it { expect { sandbox.execute('3') }.not_to(change { sandbox_class.compiled_cache.size }) }
      it { expect { sandbox.execute('3') }.to(change { sandbox_class.compiled_cache.keys }.to(%w[2 3]).from(%w[1 2])) }
    end
  end
end
