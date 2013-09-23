module RabbitDaemon
end

$:.unshift(File.expand_path(File.dirname __FILE__))
require 'common/worker'
require 'common/worker_pool'
require 'common/queue_subscriber'

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
			@logger.warn "[USR1] config reloading..."
			@need_reload = true
		end if Signal.list["USR1"]

		Signal.trap("USR2") do
			@logger.warn "[USR2] status..."
			1
		end if Signal.list["USR2"]

		Signal.trap("TERM") do
			@logger.warn "[TERM] exit..."
			@running = false
		end if Signal.list["TERM"]
		Signal.trap("INT") do
			@logger.warn "[INT] exit..."
			@running = false
		end if Signal.list["INT"]
	end

	def process()
		status_message "Processing started at #{Time.new.to_s}"
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
			sleep(sleep_time)
		end
		status_message "Processing completed at #{Time.new.to_s}"
	end

	def status_message(msg)
		puts msg
		@logger.warn msg
	end
end
