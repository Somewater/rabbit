require "json"

class BaseController < Application

	def initialize request
		@params = request.params || {}

		# проверить авторизацию
		return unless authorization @params

		# обработать JSON
		parce @params['json']
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


	def call
		# ping-pong
		JSON.generate(@json)
	end
end