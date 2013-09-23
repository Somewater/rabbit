module RabbitDaemon
	class WorkerPool < Worker
		attr_reader :workers, :time

		def initialize(workers)
			@workers = workers
			@time = 0
		end

		def run
			t = Time.new.to_f
			@workers.dup.each do |worker|
				begin
					worker.run()
				rescue Exception => err
					logger.error "Exception: #{err}"
					@workers.delete(worker)
				end
			end
			@time += (Time.new.to_f - t)
		end
	end
end
