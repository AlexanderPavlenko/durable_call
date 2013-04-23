require 'durable_call/version'
require 'durable_call/caller'

module DurableCall
  def self.call(subject, args, options={}, &block)
    DurableCall::Caller.new(subject, options).call(*Array(args), &block)
  end
end
