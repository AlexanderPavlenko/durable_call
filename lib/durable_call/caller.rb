require 'timeout'

module DurableCall

  class RetriesError < RuntimeError; end
  TimeoutError = Timeout::Error

  class Caller

    INTERVALS = {
      :rand => lambda{|_| rand },
      # TODO: progression with the increasing delays between retries
    }.freeze

    MESSAGES = {
      :new_retry => 'Retry #%1$i',
      :failed_call => 'Failed to call %1$s on %2$s: %3$s',
      :waiting_before_retry => 'Waiting %1$.2f seconds before retry',
      :retries_error => 'Number of retries exceeded: %1$i',
      :timeout_error => 'Timeout exceeded: %1$.2f',
    }.freeze

    attr_reader :subject

    def initialize(subject, options={})
      @subject = subject
      { # default options
        :interval => :rand,
        :logger   => nil,
        :retries  => 0,
        :timeout  => nil,
      }.each do |key, value|
        instance_variable_set :"@#{key}", options.key?(key) ? options[key] : value
      end
    end

    def call(*args)
      Timeout.timeout(@timeout) do
        # we want to return as soon as result will be obtained
        called = false
        result = nil
        (0..@retries).each do |retries_counter|
          # @timeout may be exceeded here and exception will be raised
          begin
            if retries_counter > 0
              # first try isn't "retry"
              log :info, :new_retry, retries_counter
            end
            result = @subject.__send__ *args
            called = true
          rescue => ex
            log :warn, :failed_call, args.inspect, @subject, ex.inspect
            if @interval && retries_counter < @retries
              # interval specified and it's not a last iteration
              sleep_before_retry(retries_counter + 1)
            end
          else
            break
          end
        end
        if called
          result
        else
          log :error, :retries_error, @retries
          raise RetriesError
        end
      end
    rescue TimeoutError
      log :error, :timeout_error, @timeout
      raise
    end

  private

    def sleep_before_retry(retries_counter)
      seconds = if @interval.is_a? Symbol
        INTERVALS[@interval].call(retries_counter)
      elsif @interval.respond_to?(:call)
        @interval.call(retries_counter)
      else
        @interval
      end
      # sleep before next retry if needed
      if seconds > 0
        log :info, :waiting_before_retry, seconds
        sleep seconds
      end
    end

    def log(level, message, *args)
      return unless @logger
      @logger.send level, MESSAGES[message] % args
    end
  end
end
