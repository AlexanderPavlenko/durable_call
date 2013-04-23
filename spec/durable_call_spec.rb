require 'spec_helper'
require 'logger'

describe DurableCall do

  before :all do
    @subject_class = Class.new do
      def simple_method
        true
      end
      def long_method(seconds)
        sleep seconds
        true
      end
      def failing_method(condition)
        raise RuntimeError.new("it happens") if condition.call
        true
      end
      def worse_method(seconds, condition)
        sleep seconds
        raise RuntimeError.new("it happens") if condition.call
        true
      end
    end.freeze
    @subject = @subject_class.new.freeze
  end

  before do
    @log = StringIO.new
    @logger = Logger.new(@log)
  end

  it 'should have a version number' do
    DurableCall::VERSION.should_not be_nil
  end

  it 'has default settings' do
    @wrapper = DurableCall::Caller.new(@subject)
    @wrapper.instance_variable_get(:@interval).should == :rand
    @wrapper.instance_variable_get(:@logger  ).should == nil
    @wrapper.instance_variable_get(:@retries ).should == 0
    @wrapper.instance_variable_get(:@timeout ).should == nil
  end

  it 'has subject reader' do
    @wrapper = DurableCall::Caller.new(@subject)
    @wrapper.subject.should === @subject
  end

  it 'invokes simple methods' do
    @wrapper = DurableCall::Caller.new(@subject, :logger => @logger)
    @wrapper.call(:simple_method).should == true
    @log.string.should == ''
  end

  it 'invokes long method' do
    @wrapper = DurableCall::Caller.new(@subject, :timeout => 0.1, :logger => @logger)
    expect{ @wrapper.call(:long_method, 1) }.to raise_error(DurableCall::TimeoutError)
    valid_log?(@log.string, [
      /E.*Timeout exceeded: 0.10/,
    ]).should == true
  end

  it 'invokes not so long method' do
    @wrapper = DurableCall::Caller.new(@subject, :timeout => 0.1, :logger => @logger)
    @wrapper.call(:long_method, 0.09).should == true
    @log.string.should == ''
  end

  it 'invokes failing method' do
    @wrapper = DurableCall::Caller.new(@subject)
    (condition = mock).should_receive(:call).once.and_return(true)
    expect{ @wrapper.call(:failing_method, condition) }.to raise_error(DurableCall::RetriesError)
  end

  it 'invokes failing method with constant intervals and logging' do
    @wrapper = DurableCall::Caller.new(@subject, :retries => 2, :interval => 0.0123, :logger => @logger)
    (condition = mock).should_receive(:call).exactly(3).times.and_return(true)
    expect{ @wrapper.call(:failing_method, condition) }.to raise_error(DurableCall::RetriesError)
    valid_log?(@log.string, [
      error   = /W.*Failed to call \[\:failing_method, .*RuntimeError\: it happens/,
      waiting = /I.*Waiting 0\.01 seconds before retry/,
      /I.*Retry \#1/,
      error,
      waiting,
      /I.*Retry \#2/,
      error,
      /E.*Number of retries exceeded: 2/,
    ]).should == true
  end

  it 'invokes failing method with :rand intervals and logging' do
    @wrapper = DurableCall::Caller.new(@subject, :retries => 1, :logger => @logger)
    (condition = mock).should_receive(:call).exactly(2).times.and_return(true)
    expect{ @wrapper.call(:failing_method, condition) }.to raise_error(DurableCall::RetriesError)
    valid_log?(@log.string, [
      error = /W.*Failed to call \[\:failing_method, .*RuntimeError\: it happens/,
      /I.*Waiting [01]\.\d\d seconds before retry/,
      /I.*Retry \#1/,
      error,
      /E.*Number of retries exceeded: 1/,
    ]).should == true
  end

  it 'invokes failing method with custom intervals and logging' do
    @wrapper = DurableCall::Caller.new(@subject, :retries => 2, :interval => lambda{|i| i / 100.0 }, :logger => @logger)
    (condition = mock).should_receive(:call).exactly(3).times.and_return(true)
    expect{ @wrapper.call(:failing_method, condition) }.to raise_error(DurableCall::RetriesError)
    valid_log?(@log.string, [
      error   = /W.*Failed to call \[\:failing_method, .*RuntimeError\: it happens/,
      /I.*Waiting 0\.01 seconds before retry/,
      /I.*Retry \#1/,
      error,
      /I.*Waiting 0\.02 seconds before retry/,
      /I.*Retry \#2/,
      error,
      /E.*Number of retries exceeded: 2/,
    ]).should == true
  end

  it 'invokes not so failing method' do
    @wrapper = DurableCall::Caller.new(@subject, :retries => 2, :interval => 0.0123, :logger => @logger)
    (condition = mock).should_receive(:call).twice.and_return(true, false)
    @wrapper.call(:failing_method, condition).should == true
    valid_log?(@log.string, [
      /W.*Failed to call \[\:failing_method, .*RuntimeError\: it happens/,
      /I.*Waiting 0\.01 seconds before retry/,
      /I.*Retry \#1/,
    ]).should == true
  end

  it 'invokes worse method' do
    @wrapper = DurableCall::Caller.new(@subject, :retries => 2, :interval => 0.05, :timeout => 0.1, :logger => @logger)
    (condition = mock).should_receive(:call).once.and_return(true)
    expect{ @wrapper.call(:worse_method, 0.05, condition) }.to raise_error(DurableCall::TimeoutError)
    valid_log?(@log.string, [
      /W.*Failed to call \[\:worse_method, .*RuntimeError\: it happens/,
      /I.*Waiting 0\.05 seconds before retry/,
      /E.*Timeout exceeded: 0.10/,
    ]).should == true
  end

  it 'has shorthand module method' do
    DurableCall.call(@subject, :simple_method)
    DurableCall.call(@subject, [:long_method, 0.01], {:logger => @logger, :timeout => 0.1})
  end

  def valid_log?(log, regexps)
    puts "#{'-' * 20}\n", log
    raise ArgumentError if log.lines.count != regexps.size
    log.lines.zip(regexps).all?{|(string, regexp)| string =~ regexp }
  end
end
