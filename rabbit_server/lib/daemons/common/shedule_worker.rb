module RabbitDaemon
	class SheduleWorker
		attr_reader :schedule
		def initialize(schedule)
			@schedule = schedule
		end

		def run()
			if can_shedule_run?
				shedule_run()
			end
		end
		
		def shedule_run()
			@logger.debug{ "#{self.to_s}.shedule_run()" }
		end

		protected
		def can_shedule_run?
			
		end
	end
end
