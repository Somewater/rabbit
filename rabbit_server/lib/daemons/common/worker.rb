module RabbitDaemon
	class Worker
		attr_writer :logger

		def logger(value)
			@logger ||= Logger.new(STDOUT)
		end

		def run()
			@logger.debug{ "#{self.to_s}.run()" }
		end

		def start()
			@logger.debug{ "#{self.to_s}.start()" }
		end

		def reload()
			@logger.debug{ "#{self.to_s}.reload()" }
		end

		def stop()
			@logger.debug{ "#{self.to_s}.stop()" }
		end
	end
end
