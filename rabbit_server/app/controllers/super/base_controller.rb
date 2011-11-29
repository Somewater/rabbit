require "json"

class BaseController

	###########
	#
	#	Переменные
	#	класса
	#
	###########
	@@api_by_id = {}
	@@api_by_name = {}
	def self.api_by_name; @@api_by_name end
	def self.api_by_id; @@api_by_id end

	attr_accessor :api, :params, :response, :json

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


			# обработать JSON
			parce @params['json']
			@response = {:pong => @params['ping'].to_i}

			authorized

			@models_to_save = []

			# что-то делаем
			process

			# сохраняем результаты работы в базу, перед отправкой на клиент
			save_data
		end
	end

	def authorization params
		if DEVELOPMENT
			@api = EmbedApi.new(params)
			params['uid'] && params['key']
		else
			net = params['net'] ? params['net'].to_sym : nil
			raise AuthError, 'Empty net identificator' unless net
			if self.class.api_by_id[params['net'].to_i]
				@api = self.class.api_by_id[params['net'].to_i].new(params)
			elsif self.class.api_by_name[net]
				@api = self.class.api_by_name[net].new(params)
			elsif params['net'] =~ /local\:\w+/
				@api = EmbedApi.new(params)
			else
				raise AuthError, 'Undefined net identificator'
			end
			true
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
		@models_to_save.each{|record| record.save() }
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

=begin
	добавить объект типа ActiveRecord в очередь на сохранение
=end
	protected
	def save(active_record)
		@models_to_save << active_record unless @models_to_save.index(active_record)
	end
end
