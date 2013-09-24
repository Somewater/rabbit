module RabbitDaemon
end

$:.unshift(File.expand_path(File.dirname __FILE__))
require 'common/worker'
require 'common/worker_pool'
require 'common/queue_subscriber'

class RabbitDaemon::Processor

	attr_accessor :sleep_time
	
	def initialize(worker, logger, pidfile_path)
		@worker = worker
		@logger = logger
		@running = true
		@started = false
		@need_reload = false
		@pidfile_path = pidfile_path
		setup_traps()

		@sleep_time = 0
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
		raise "Some process already exist. Pidfile exist" if File.exist?(@pidfile_path) && File.open(@pidfile_path).read.to_s.size > 0
		Process.daemon(true)
		pidfile = File.new(@pidfile_path, "w")
		pidfile.sync = true
		pidfile << Process.pid.to_s
		status_message "Processing daemonized at #{Time.new.to_s}, PID #{Process.pid}"
		loop do
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
			sleep(@sleep_time) if @sleep_time > 0
		end
		status_message "Processing completed at #{Time.new.to_s}"
		pidfile.close
		File.delete(@pidfile_path)
	end

	def status_message(msg)
		puts msg
		@logger.warn msg
	end
end
