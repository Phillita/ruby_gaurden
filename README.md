# RubyGaurden

RubyGaurden allows the execution of untrusted Ruby code safely in a walled garden. It works by compiling Ruby code to JavaScript using [`opal`](https://github.com/opal/opal) and executing it in [Google's V8 Engine](https://github.com/cowboyd/libv8) with some help from [`mini_racer`](https://github.com/discourse/mini_racer).

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'ruby_gaurden'
```

And then execute:

```bash
bundle

```

Or install it yourself as:

```bash
gem install ruby_gaurden
```

## Usage

```ruby
# `RubyGaurden::Gaurden` is the sandbox base class. It has only the bare essentials to get the environment working.
class MySandbox < RubyGaurden::Bed
  # Code in the sandbox will block at most one second
  times_out_in 1 # Seconds

  # Makes the opal gem available for requiring inside the sandbox
  uses 'opal'

  # Requires the Opal compiler inside the sandbox (enables advanced runtime meta-programming like `Kernel#eval`)
  requires 'opal-parser'

  # Exposes the #native_add method to code running inside the sandbox
  exposes :native_add

  # Executes some code in the sandbox to setup it's runtime state
  executes <<-RUBY
    $global_state = 1337

    # Some boilerplate code
    class PlayThing
      attr_reader :name

      def initialize(name)
        @name = name
      end

      # Code inside of the sandbox can get a handle on the box with `RubyGaurden.current` and call exposed methods
      def add(a, b)
        RubyGaurden.current.native_add(a, b)
      end
    end
  RUBY

  def native_add(a, b)
    a + b
  end
end

untrusted_program = <<-RUBY
  $global_state = 'tainted'

  puts "Hello, world"

  car = PlayThing.new("Car")
  car.name
RUBY

# Every instance of the sandbox starts with the state configured on the class
my_sandbox = MySandbox.new
my_sandbox.execute(untrusted_program) #=> "Car"
my_sandbox.execute('PlayThing.add(2,7)') #=> 9
my_sandbox.stdout #=> ["Hello, world\n"]

# You can also call top-level methods directly using #call
my_sandbox.execute('def sum(a, b); a + b; end')
my_sandbox.call(:sum, 10, 20) #=> 30

### When to use #call vs #execute
# Every instance of the sandbox starts with the state configured on the class
While both methods run code inside the sandbox, they serve different purposes:

*   **Use `#execute`** for running arbitrary scripts, defining classes/methods, or setting up state. It involves a compilation step (Ruby to JavaScript) which, while cached, is more "heavyweight."
*   **Use `#call`** to invoke specific methods that already exist in the sandbox. It is faster because it skips the compiler and directly targets the V8 runtime. It also handles the serialization of arguments automatically, making it the safest way to pass host data into the sandbox.

A common pattern is to use `executes` at the class level to define your API, and then use `#call` at runtime to trigger it.

# Every instance of the sandbox is isolated
another_sandbox = MySandbox.new
another_sandbox.execute('$global_state') #=> 1337

# It also has an stderr
another_sandbox.execute('warn "This looks dangerous"')
another_sandbox.stderr #=> ["This looks dangerous\n"]

# Exceptions comes through as subclasses of RubyGaurden::BedError
another_sandbox.execute('nil.no_method') #=> RubyGaurden::BedError::BedNoMethodError

# You can determine if you are in a sandbox using `RubyGaurden.planted?` and `RubyGaurden.current`
RubyGaurden.planted? #=> false
RubyGaurden.current #=> nil

### Inheritance
# Sandboxes inherit configuration (uses, requires, executes, exposes) from their parents.
class BaseSandbox < RubyGaurden::Gaurden
  executes '$base_initialized = true'
end

class SpecializedSandbox < RubyGaurden::Gaurden
  executes '$special_initialized = true'
end

box = SpecializedSandbox.new
box.execute('$base_initialized')    #=> true
box.execute('$special_initialized') #=> true
```

## Performance & Caching

RubyGaurden caches the compiled JavaScript of every snippet passed to `execute`. This drastically improves performance for repeated calls.

To prevent memory exhaustion in long-running processes, the cache is limited to `MAX_CACHE_SIZE` (default 1000) entries per sandbox class. When the limit is reached, the cache is cleared.

```ruby
RubyGaurden::RuntimeEnvironment::MAX_CACHE_SIZE #=> 1000
```

## Development

The development dependencies of this gem are managed using [Bundler](https://rubygems.org/gems/bundler).

After checking out the repo, run `bundle install` to install dependencies. Then, run `bundle exec rake spec` to run the tests. You can also run `bundle exec rake console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [RubyGems](https://rubygems.org/gems/ruby_gaurden).

## Contributing

Bug reports and pull requests are welcome on [GitHub](https://github.com/Phillita/ruby_gaurden).


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
