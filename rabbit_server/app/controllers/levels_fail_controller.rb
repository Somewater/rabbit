# ведет учет траты энергии на неуспешное прохождение уровня
class LevelsFailController < BaseUserController

	include RequestSecurity

	# прогнать левел инстанс через server_logic и выдать ответ клиенту
	def process
		raise LogicError, "Energy already ended" unless @user.debit_energy()
		@response['user'] = @user.to_json
	end
end
