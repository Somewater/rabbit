# дополнительная проверка на переписывания json
module RequestSecurity
	def authorized
		# базовая проверка
		super

		raise UnimplementedError, 'Must have user data (BaseUserController class)'  unless @user

		# проверка на секьюрность json
		raise AuthError, 'Unsecured request' unless @params['secure']

		roll = (@user.get_roll * 1000).to_i
		md5 = Digest::MD5.hexdigest("lorem #{@params['json'].reverse} ipsum #{@params['uid']} #{@params['net']} #{roll}")
		raise AuthError, 'Unsecured json string' unless md5 == @params['secure']
	end
end