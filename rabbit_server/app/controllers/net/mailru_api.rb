require "httparty"

class MailryApi < NetApi

	def authorized?(uid, key, params = nil)
		Digest::MD5.hexdigest(CONFIG["mailru"]["app_id"].to_s + '_' + uid.to_s + '_' + CONFIG["mailru"]["secure_key"]) == key.to_s
	end

	def self.id
		3
	end

	def name
		:mailru
	end
	
	def notify(target, text, params = nil)
		begin
			user_uids = NetApi.arg_to_ids(target)
			response = nil
			response = get('notifications.send', {:uids => user_uids.join(','), :text => text})
			response.to_a
		rescue
			Application.logger.error("[ERROR] [NOTIFY]\n#{user_uids} => #{$!} #{$!.backtrace}")
			false
		end
	end

	def pay(user, value, params = nil)
		raise UnimplementedError, "Override me"	
	end

	private
	def get(method, params)
		params.merge!({:method => method,
					   :app_id => CONFIG["mailru"]["app_id"],
					   :uid => 12438175227095110559,
					   :secure => 1})
		params_str = params.sort.map{|a| "#{a.first}=#{a.last}"}.join
		params[:sig] = Digest::MD5.hexdigest(params_str + CONFIG["mailru"]["secure_key"])
		HTTParty.get('http://www.appsmail.ru/platform/api', :query => params)
	end
end
