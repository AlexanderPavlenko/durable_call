require 'benchmark'
require File.expand_path('../../lib/durable_call.rb', __FILE__)

n = 500000
Benchmark.bm do |bm|
  object = Object.new
  caller = DurableCall::Caller.new(object)

  bm.report do
    n.times do
      object.__send__ :object_id
    end
  end

  bm.report do
    n.times do
      caller.call(:object_id)
    end
  end

  bm.report do
    n.times do
      DurableCall.call(object, :object_id)
    end
  end
end
