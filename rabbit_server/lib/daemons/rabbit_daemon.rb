module RabbitDaemon
end

require_relative 'common/worker'
require_relative 'common/worker_pool'

class RabbitDaemon::Processor
  
  def initialize(worker, logger)
    @worker = worker
    @logger = logger
    @running = true
    @started = false
    @need_reload = false
    setup_traps()
  end

  def setup_traps()
    Signal.trap("USR1") do
      @need_reload = true
    end
    Signal.trap("TERM") do
      @running = false
    end
  end

  def process(worker)
    loop do
      sleep_time = 5
      time = Time.new.to_f
      begin
        unless @running
          @worker.stop()
          break
        end
        unless @started
          @worker.start()
          @started = true
        end
        if @need_reload
          @worker.reload()
          @need_reload = false
        end
        @worker.run()
      rescue Exception => err
        @logger.error "Exception: #{err}"
        break
      end
      @logger.debug{ "time=#{Time.new}" }
      sleep(sleep_time)
    end
  end
end
