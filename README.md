# SidekiqSimpleDelay

Adds Sidekiq [Delay](https://github.com/mperham/sidekiq/wiki/Delayed-extensions) functionality, but adds some restrictions to prevent object marshalling.

Sidekiq's built-in delay feature only allows you to turn the functionality for all classes and only for class methods. `SidekiqSimpleDelay` allows you to specify classes you want to enable the delay methods for. In addition to class methods, since we are now checking and restricting the arguments to be simple JSON convertable objects, we can add this delay functionality to instances of classes.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'sidekiq_simple_delay'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install sidekiq_simple_delay

## Usage

You can find the docs on [rubdoc.info](https://www.rubydoc.info/github/Latermedia/sidekiq_simple_delay/master).

### All Classes

To add delay functionality all classes. This is similar to `Sidekiq::Extensions.enable_delay!`.

```ruby
SidekiqSimpleDelay.enable_delay!

MyClass.simple_delay.some_method(:arg)
```

### Single Class

We can also add the functionality to a single class:
```ruby
class User
  extend SidekiqSimpleDelay::DelayMethods

  def self.greeting
    'Hello Everyone'
  end
end

# ...

User.simple_delay.greeting
User.simple_delay_for(10.minutes).greeting
User.simple_delay_until(1.day.from_now).greeting
```

To add delay functionality to the instances of a class:
```ruby
class User
  include SidekiqSimpleDelay::DelayMethods

  def greeting(name)
    "Hello, #{name}"
  end
end

# ...

User.new.simple_delay.greeting('Les')
```

### Simple Delay Methods

Three methods are provided that map to the three main invocations for Sidekiq.
* `simple_delay` -> `perform_async`
* `simple_delay_for` -> `perform_in`
* `simple_delay_until` -> `perform_at`

### Simple Delay Spread

Often we want to enqueue a bunch of jobs, but need to spread them out over some period of time to prevent swampping our resources. We use a similar API to [`sidekiq_spread`](https://github.com/Latermedia/sidekiq_spread) to evenly distribute job execution.

```ruby
class User
  extend SidekiqSimpleDelay::DelayMethods

  def greeting(name)
    "Hello, #{name}"
  end
end

# ...

spread_options = {
  spread_duration: 3.hours,
  spread_in: 15.minutes
}

# Randomly enqueues a job sometime between 15 minutes and 3 hours
# and 15 minutes from now
User.simple_delay_spread(spread_options).greeting('Les')
```

### Devops

A few conveniences are provided that allow you enable this functionality from the command line.

Let's say we have a class the contains a long running method that we want to push to the background. In the past we'd have to make a one time worker to run this job. Now we can create the job directly from our console without modifying the class's code.

```ruby
class Task
  def self.long_running_task(task_arg1, task_arg2)
    # things that take a long time...
  end
end
```

From the console:
```ruby
SidekiqSimpleDelay.enable_delay_class!(Task)

Task.simple_delay.long_running_task('things', 1234)
```

The great thing is, assuming you have added `sidekiq_simple_delay` to your `Gemfile`, this will just work™. The job that is enqueued doesn't need `Task` to know anything about Sidekiq, workers, or jobs.

Similar to `enable_delay_class!` there is also `enable_delay_instance!` to do the same thing for instances and instance methods of `Task`.

```ruby
SidekiqSimpleDelay.enable_delay_instance!(Task)

Task.new.simple_delay.long_running_tasks_instance_method
```

### Delaying Instances

Delaying class methods is pretty simple and straight forward. There is no state to keep track of, so we just pass the class, the method name and whatever arguments we need. In order to be able to delay methods on an instance we have to do some book keeping and add some limitations.

`Klass` can delay method invocation on it's instances if:
* `Klass.new` takes no arguments
or
* `Klass` implements the public instance method `initialize_args` which returns an array of arguments to be used to initialize an instance of `Klass` in the `SimpleDelayedWorker`

To implement custom instantiation within the `SimpleDelayedWorker`, `Klass` can implement the `simple_delay_initialize` public class method that takes the same arguments `initialize_args` returns.

One use case of these methods would be for delaying methods on an `ActiveRecord` objects.

```ruby
class ApplicationRecord < ActiveRecord::Base
  def initialize_args
    [send(self.class.primary_key)]
  end

  def self.simple_delay_initialize(*args)
    find(args[0])
  end
end

class User < ApplicationRecord
  def long_running_user_task(arg1)
    # takes a long time
  end
end
```

From the console:
```ruby
SidekiqSimpleDelay.enable_delay_instance!(User)

User.where(column1: true).find_each do |user|
  user.simple_delay.long_running_user_task('things')
end
```

In fact, this is exactly what `sidekiq_delay` does with its `ActiveRecord` integration. To enable it,

```ruby
SidekiqSimpleDelay.enable_delay_active_record!
```

This will try to add the methods to `ApplicationRecord` first if it exists, but falls back to `ActiveRecord::Base` if it doesn't. You can also add it a single class if you want.

```ruby
SidekiqSimpleDelay.enable_delay_active_record!(User)
```
To spread these jobs out over an interval of time:
```ruby
  spread_options = {
    spread_duration: 8.hours,
    spread_at: 3.hours.from_now,
    spread_method: :mod,
    spread_mod_method: :id
  }

  User.where(column1: true).find_each do |user|
    user.simple_delay_spread(spread_options).long_running_user_task('things')
  end
```

By modding on the id of the `User` object, we can be sure that if we run this script with the same options, each user job will be executed at about the same relative time. This is useful if you have recurring jobs where having a deterministic offset for a user is beneficial.

### Simple Objects

`SidekiqSimpleDelay` only allows simple objects to be used as parameters to the delayed method. These objects are:

* `NilClass`
* `TrueClass`
* `FalseClass`
* `String`
* `Symbol`
* `Hash`
* `Array`
* `Float`
* `Integer` (`RUBY_VERSION` >= 2.4.0)
* `Fixnum` (`RUBY_VERSION` < 2.4.0)
* `Bignum` (`RUBY_VERSION` < 2.4.0)

`SidekiqSimpleDelay::Utils.simple_object?` will do a depth first recursive check to make sure nothing but the above makes it into the arguments.

In addition requiring arguments being simple, a requirement of no keyword or block arguments is imposed. There is a chance the keyword argument restriction could be lifted, but this would take a fair bit of work in `SimpleDelayedWorker` to get working correctly. For now the restriction is there to keep one from shooting themselves in the foot.

## Logging

`sidekiq_simple_delay` hijacks the `wrapped` job parameter used by `ActiveJob` to log the class and method name being used. The logged "class" will look something like:

Class method:

`SimpleDelayed=MyClass::class_meethod`

Instance method:

`SimpleDelayed=MyClass#instance_meethod`

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Tests

Since parts of the functionality is optional and modifies other classes and objects, the specs aren't meant to be run all at the same time. This is to isolate the environment the tests are executing in.

To run the tests:

```bash
./run_specs
```

Tests are currently run against the following Ruby version:
- 2.5
- 2.4
- 2.3
- 2.2

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/Latermedia/sidekiq_simple_delay. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the SidekiqSimpleDelay project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/Latermedia/sidekiq_simple_delay/blob/master/CODE_OF_CONDUCT.md).
