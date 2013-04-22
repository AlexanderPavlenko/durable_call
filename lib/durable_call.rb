require 'durable_call/version'
require 'durable_call/caller'

module DurableCall
  def self.call(subject, args, options={})
    DurableCall::Caller.new(subject, options).call(*Array(args))
  end
end
