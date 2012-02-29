class MailryApi < NetApi

	def authorized?(uid, key, params = nil)
		Digest::MD5.hexdigest(CONFIG["mailru"]["app_id"] + '_' + uid.to_s + '_' + CONFIG["mailru"]["secure_key"]) == key.to_s
	end

	def self.id
		3
	end
	
	def notify(target, text, params = nil)
		false	
	end

	def pay(user, value, params = nil)
		raise UnimplementedError, "Override me"	
	end
end
