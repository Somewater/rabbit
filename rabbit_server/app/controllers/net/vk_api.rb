# encoding: utf-8

class VkApi < NetApi
	
	def authorized?(uid, key, params = nil)
		Digest::MD5.hexdigest(CONFIG["vkontakte"]["app_id"].to_s + '_' + uid.to_s + '_' + CONFIG["vkontakte"]["secure_key"]) == key.to_s
	end

	# проверка авторизации обращения сервера соц. сети
	def request_authorized?(params)
		sig = params['sig']
		return false unless sig
		str = params.select{|k,v| k.to_s != 'sig' }.sort{|a,b| a.first <=> b.first }.map{|a| a.first.to_s + '=' + a.last.to_s }.join('')
		Digest::MD5.hexdigest(str + CONFIG["vkontakte"]["secure_key"].to_s) == sig
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

	def payment(request)
		return error_response(10) unless request_authorized?(request.params)
		if request.params['notification_type'] == 'get_item' ||
				(!PRODUCTION && request.params['notification_type'] == 'get_item_test')
			{:response => get_item_info(request.params['item'], request.params['lang'].to_s[0,2])}.to_json
		elsif request.params['notification_type'] == 'order_status_change' ||
				(!PRODUCTION && request.params['notification_type'] == 'order_status_change_test')
			raise FormatError, "Unsupported status #{request.params['status']}" unless request.params['status'] == 'chargeable'
			order_id = request.params['order_id'].to_i
			raise FormatError, "order_id not assigned = #{request.params['order_id']}" if order_id <= 0
			app_order_id = order_status_change(request.params['receiver_id'], request.params['item'], request.params['item_price'].to_i).to_i
			{:response => {:order_id => order_id, :app_order_id => app_order_id}}.to_json
		else
			error_response(11, "Unsupported notification type #{request.params['notification_type']}")
		end
	rescue Exception => error
		Application.logger.warn "payment error: #{error}\n#{error.backtrace.join(?\n)}"
		return error_response(1, error.to_s)
	end

	# @param item:String выдать информацию о товаре на основе строкового идентификатора
	# @return hash {title: String, price: Int[, photo_url: String, item_id: Int, expiration: Int]}
	def get_item_info item, lang
		raise UnimplementedError, "Implement vk api method get_item_info"
	end

	# Осуществить покупку товара
	# @param item:String идентификатор товара
	# @return Int уникальный номер заказа в системе
	def order_status_change receiver_id, item, net_price
		raise UnimplementedError, "Implement vk api method order_status_change"
	end
	
	def secure_vk
		unless @secure_vk
			Vkontakte.setup do |config|
				config.app_id = CONFIG["vkontakte"]["app_id"]
				config.app_secret = CONFIG["vkontakte"]["secure_key"]
				config.format = :json
				config.debug = !PRODUCTION
				config.logger = File.open("#{ROOT}/log/vkontakte.log", "a") if DEVELOPMENT
			end
			
			@secure_vk = Vkontakte::App::Secure.new
		end
		@secure_vk
	end

	def error_response(id, msg = nil, critical = true)
		{:error => {:error_code => id.to_i, :error_msg => msg.to_s, :critical => !!critical}}.to_json
	end	
end
