# DurableCall

Invoke methods DRY and safely with parameterized retries, timeouts and logging

[![Travis CI](https://secure.travis-ci.org/AlexanderPavlenko/durable_call.png)](https://travis-ci.org/AlexanderPavlenko/durable_call)
[![Coverage Status](https://coveralls.io/repos/AlexanderPavlenko/durable_call/badge.png?branch=master)](https://coveralls.io/r/AlexanderPavlenko/durable_call)

## Installation

Add this line to your application's Gemfile:

    gem 'durable_call'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install durable_call

## Usage

Simple usage:

    DurableCall.call(Object.new, :object_id)

Multiple arguments and options:

    DurableCall.call(Something.new, [:method_name, :param, :other_param], options)

Where ```options``` may take:

    {
      :interval  # 1. lambda, which takes retry number (min 1) and returns seconds to sleep
                 # 2. just Float
                 # 3. Symbol for built-in strategies, defaults to :rand
      :logger    # Logger object, defaults to nil
      :retries   # retries number, defaults to 0
      :timeout   # operation timeout, defaults to nil (no time limits)
    }

Also, it's possible to perform multiple calls with the same options:

    caller = DurableCall::Caller.new(Something.new, options)
    caller.call(:method_name, :param, :other_param)
    caller.call(:faster_faster, :no_instantiation_overhead)

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
