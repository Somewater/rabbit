require "json"

class BaseController

=begin
	@json 			превращенный в хэш поле зарпоса params['json']
	@params 		запрос
	@authorization  статус выполнения авторизации
=end

	def initialize request
		@params = request.params || {}

		# проверить авторизацию
		unless authorization @params
			@authorization = false
			unauthorized
		else
			@authorization = true
			authorized
			# обработать JSON
			parce @params['json']
		end
	end

	def authorization params
		if DEVELOPMENT
			params['uid'] && params['key']
		else
			raise "TODO: implement authorization"#TODO: implement authrization
		end
	end

	def parce json
		begin
			@json = JSON.parse(json)
		rescue
			@json = {}
		end
	end

	def generate(hash = nil)
		begin
			JSON.generate(hash ? hash : @json)
		rescue
			'{"error":"E_JSON_GENERATING"}'
		end
	end

=begin
	Генерация ответа
=end
	def call
		# ping-pong
		JSON.generate(@json)
	end

=begin
	Действия на неавторизованный запрос
=end
	def unauthorized
		raise "Authorization error"
	end

=begin
	ействия на авторизованный запрос (перед парсингом json)
=end
	def authorized
		# do nothing
	end
end
