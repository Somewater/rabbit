# дополнительная проверка на переписывания json
require 'digest/md5'
module RequestSecurity
	def authorized
		# проверка на секьюрность json
		raise AuthError, 'Unsecured request' unless @params['secure']

		md5 = Digest::MD5.hexdigest("lorem #{@params['json'].reverse} ipsum #{@params['uid']} #{@params['net']}")
		raise AuthError, 'Unsecured json string' unless md5 == @params['secure']

		# базовая проверка
		super
	end
end