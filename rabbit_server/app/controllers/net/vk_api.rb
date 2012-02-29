class VkApi < NetApi
	
	def authorized?(uid, key, params = nil)
		Digest::MD5.hexdigest(CONFIG["vkontakte"]["app_id"].to_s + '_' + uid.to_s + '_' + CONFIG["vkontakte"]["secure_key"]) == key.to_s
	end

	def self.id
		2
	end
	
	def notify(target, text, params = nil)
		# todo target => user_uids (массив id-шников)
		begin
				response = nil
				response = secure_vk.secure.sendNotification({:uids => user_uids.join(','), :message => text})
				# todo: проверить success, выдать id-шники получателей
			rescue Vkontakte::App::VkException
				logger.error("Error when notify\n#{user_uids} => #{$!}")
				false
			rescue
				logger.fatal("Fatal when notify\n#{user_uids} => #{$!}")
				false
			end	
	end

	def pay(user, value, params = nil)
		raise UnimplementedError, "Override me"	
	end
	
	private
	def secure_vk
		unless @secure_vk
			Vkontakte.setup do |config|
				config.app_id = CONFIG["vkontakte"]["app_id"]
				config.app_secret = CONFIG["vkontakte"]["secure_key"]
				config.format = :json
				config.debug = !PRODUCTION
				config.logger = File.open("#{ROOT}/logs/vkontakte.log", "a") if DEVELOPMENT
			end
			
			@secure_vk = Vkontakte::App::Secure.new
		end
		@secure_vk
	end
end
