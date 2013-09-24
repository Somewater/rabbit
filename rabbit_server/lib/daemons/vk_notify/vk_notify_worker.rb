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
					send_notify(queue_element['uids'], queue_element['msg'])
				end
			end
		end

		def send_notify(user_uids, message)
			return if user_uids.size == 0
			user_uids.map!{|id| id.to_s}
			counter = 100000
			time = nil
			triple_time = 0
			while user_uids.size > 0 && counter > 0
				counter -= 0
				uids = user_uids.shift(100)
				begin
					response = nil
					time = Time.new.to_f
					response = @vk_app.secure.sendNotification({:uids => uids.join(','), :message => message})
					@vk_logger.warn("Success notify\n#{uids} => #{response ? response : nil}");
				rescue Vkontakte::App::VkException
					@vk_logger.error("Error when notify\n#{uids} => #{$!}")
				rescue
					@vk_logger.fatal("Fatal when notify\n#{uids} => #{$!}")
				end
				delta_time = Time.new.to_f - time
				triple_time += delta_time
				if counter % 3 == 0
					delta_time = 1.1 - triple_time
					triple_time = 0
				else
					delta_time = 0.3 - delta_time
				end
				sleep(delta_time) if delta_time > 0
			end
			raise "Counter limit" if counter == 0
		end
	end
end
