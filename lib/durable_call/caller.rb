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
      :new_retry => "Retry #%1$i",
      :failed_call => "Failed to call %1$s on %2$s: %3$s",
      :waiting_before_retry => "Waiting %1$.2f seconds before retry",
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
          begin
            @logger.info MESSAGES[:new_retry] % retries_counter if retries_counter > 0 if @logger
            result = @subject.__send__ *args
            called = true
          rescue Timeout::Error => ex
            # just reraise exception if @timeout exceeded
            raise
          rescue => ex
            # @timeout may be exceeded here and exception will be raised
            @logger.warn MESSAGES[:failed_call] % [args.inspect, @subject, ex.inspect] if @logger
            if @interval && retries_counter < @retries
              # interval specified and it's not a last iteration
              seconds = if @interval.is_a? Symbol
                INTERVALS[@interval].call(retries_counter)
              elsif @interval.respond_to?(:call)
                @interval.call(retries_counter)
              else
                @interval
              end
              # sleep before next retry if needed
              if seconds > 0
                @logger.info MESSAGES[:waiting_before_retry] % seconds if @logger
                sleep seconds
              end
            end
          else
            break
          end
        end
        if called
          result
        else
          raise RetriesError, "Number of retries exceeded: #{@retries}"
        end
      end
    end
  end
end
