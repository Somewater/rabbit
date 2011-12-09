# дополнительная проверка на переписывания json
module RequestSecurity
	def authorized
		# базовая проверка
		super

		raise UnimplementedError, 'Must have user data (BaseUserController class)'  unless @user

		# проверка на секьюрность json
		raise AuthError, 'Unsecured request' unless @params['secure']

		raise AuthError, 'Unsecured json string' unless secure_digest() == @params['secure']
	end

	def secure_roll
		1
	end

	def secure_digest()
		Digest::MD5.hexdigest("lorem #{@params['json'].reverse} ipsum #{@params['uid']} #{@params['net']} #{secure_roll().to_i}")
	end
end