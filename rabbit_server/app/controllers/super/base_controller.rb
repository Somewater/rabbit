require "json"

class BaseController

	###########
	#
	#	Переменные
	#	класса
	#
	###########

	attr_accessor :api, :params, :response, :json

=begin
	@json 			превращенный в хэш поле зарпоса params['json']
	@params 		запрос
	@authorization  статус выполнения авторизации
=end

	def initialize request = nil
		Application.controller = self
		@trace = nil
		start(request) if request
	end

	def start(request)
		@params = request.params || {}
		@models_to_save = []

		# проверить авторизацию
		unless authorization @params
			@authorization = false
			unauthorized
		else
			@authorization = true


			# обработать JSON
			parce @params['json']
			@response = {:pong => @params['ping'].to_i}

			authorized

			# что-то делаем
			process

			# сохраняем результаты работы в базу, перед отправкой на клиент
			save_data
		end
	end

	def authorization params
		if DEVELOPMENT
			@api = EmbedApi.new()
			params['uid'] && params['key']
		else
			net = params['net'] ? params['net'].to_s.to_sym : nil
			raise AuthError, "Empty net identificator #{params}" unless net
			@api = NetApi.by_net(params['net'])
			raise AuthError, 'Undefined net identificator' unless @api
			@api.authorized?(params['uid'].to_s, params['key'].to_s)
		end
	end

	def parce json
		begin
			@json = JSON.parse(json)
		rescue
			raise FormatError, 'Client JSON parsing error'
		end
	end

	def call
		begin
			@response['trace'] = @trace if @trace
			Application.controller = nil if Application.controller == self
			JSON.fast_generate(@response)
		rescue
			'{"error":"E_JSON_GENERATING"}'
		end
	end

=begin
	Генерация ответа. Инфу для клиента надо оформить в виде хэша
=end
	def process
		# ping-pong
		@response = @json
	end

=begin
    Сохранение всех инстансов ActiveRecord
=end
	def save_data
		ActiveRecord::Base.transaction do
			@models_to_save.each{|record| record.save() }
		end
	end

=begin
	Действия на неавторизованный запрос
=end
	def unauthorized
		raise AuthError, "Authorization error"
	end

=begin
	действия на авторизованный запрос (перед парсингом json)
=end
	def authorized
		# do nothing
	end

	def trace(msg)
		@trace = '' unless @trace
		@trace << "#{msg}\n"
	end

=begin
	добавить объект типа ActiveRecord в очередь на сохранение
=end
	protected
	def save(active_record)
		@models_to_save << active_record unless @models_to_save.index(active_record)
	end
end
