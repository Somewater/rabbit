class VkApi < NetApi
	
	def authorized?(uid, key, params = nil)
		Digest::MD5.hexdigest(CONFIG["vkontakte"]["app_id"].to_s + '_' + uid.to_s + '_' + CONFIG["vkontakte"]["secure_key"]) == key.to_s
	end

	def self.id
		2
	end

	def name
		:vkontakte
	end
	
	def notify(target, text, params = nil)
		begin
			response = nil
			user_uids = NetApi.arg_to_ids(target)
			response = secure_vk.secure.sendNotification({:uids => user_uids.join(','), :message => text})
			response['response'].split(',')
		rescue Vkontakte::App::VkException
			Application.logger.error("[ERROR] [NOTIFY]\n#{user_uids} => #{$!} #{$!.backtrace}")
			false
		rescue
			Application.logger.fatal("[FATAL] [NOTIFY]\n#{user_uids} => #{$!} #{$!.backtrace}")
			false
		end
	end

	def pay(user, value, params = nil)
		user = user.uid if user.is_a?(User)
		begin
			response = secure_vk.secure.withdrawVotes({:uid => user, :votes => (value.to_i * 100)}) || '{"error":IO}'
			response = response || {:error => 'JSON parsing'}
			response['response'].to_i == (value.to_i * 100) ? nil : response
		rescue Vkontakte::App::VkException
			Application.logger.error("[ERROR] [PAY]\n#{user},#{value} => #{$!} #{$!.backtrace}")
			$!
		rescue
			Application.logger.fatal("[FATAL] [PAY]\n#{user},#{value} => #{$!} #{$!.backtrace}")
			$!
		end
	end
	
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
