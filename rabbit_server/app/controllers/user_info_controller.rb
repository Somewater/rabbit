class UserInfoController < BaseUserController
	# прогнать левел инстанс через server_logic и выдать ответ клиенту
	def process
		raise FormatError, "Request has bad format" unless @json['user'] && @json['user']['uid']
		@personage = User.find_by_uid(@json['user']['uid'], @params['net'])
		raise LogicError, "User uid #{@json['user']['uid']} not found" unless @personage

		@response['info'] = @personage.to_json
	end
end