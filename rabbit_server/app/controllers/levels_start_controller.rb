# ведет учет траты энергии на неуспешное прохождение уровня
class LevelsStartController < BaseUserController

	# прогнать левел инстанс через server_logic и выдать ответ клиенту
	def process
		level_number = json['levelNumber'].to_i

		raise LogicError, "Energy already ended" unless @user.debit_energy()
		raise LogicError, "Need #{level_number} user level" unless @user.level >= level_number
		@response['user'] = @user.to_json
	end
end
