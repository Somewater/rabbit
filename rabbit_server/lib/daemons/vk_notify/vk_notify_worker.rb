require "vkontakte"

module RabbitDaemon
	class VkNotifyWorker < Worker
		
		include QueueSubscriber
		QUEUE_NAMESPACE = 'vk_notify_queue'
		RUN_TIMEOUT = 5

		def initialize
			initialize_queue(QUEUE_NAMESPACE)

			@vk_logger = Logger.new(File.join(ROOT, %W{ log vkontakte.log}))
			@vk_logger.level = Logger::Severity::WARN
			@vk_logger.formatter = Logger::Formatter.new

			Vkontakte.setup do |config|
				config.app_id = CONFIG["vkontakte"]["app_id"]
				config.app_secret = CONFIG["vkontakte"]["secure_key"]
				config.format = :json
				config.debug = !PRODUCTION
				config.logger = @vk_logger
			end

			@vk_app = Vkontakte::App::Secure.new
		end

		def run()
			t = Time.new.to_f
			loop do
				break if (Time.new.to_f - t) > RUN_TIMEOUT
				break if self.queue_size() == 0
				queue_element = self.shift_from_queue()
				if queue_element
					send_notify(queue_element)
				end
			end
		end

		def send_notify(user_uids)
			reruen if user_uids.size == 0
			user_uids.map!{|id| id.to_s}
			counter = 100000
			while user_uids.size > 0 && counter > 0
				counter -= 0
				uids = user_uids.shift(100)
				begin
					response = nil
					puts "Sending... #{uids.join(',')[0,10]}"; sleep(0.5)
					#response = @vk_app.secure.sendNotification({:uids => uids.join(','), :message => notify.message})
					@vk_logger.warn("Success notify\n#{uids} => #{response ? response : nil}");
				rescue Vkontakte::App::VkException
					@vk_logger.error("Error when notify\n#{uids} => #{$!}")
				rescue
					@vk_logger.fatal("Fatal when notify\n#{uids} => #{$!}")
				end
				if counter % 3 == 0
					sleep(0.5)
				else
					sleep(0.3)
				end
			end
			raise "Counter limit" if counter == 0
		end
	end
end
