# ведет учет траты энергии на неуспешное прохождение уровня
class LevelsStartController < BaseUserController

	# прогнать левел инстанс через server_logic и выдать ответ клиенту
	def process
		level_number = json['levelNumber'].to_i

		if level_number > 1
			raise LogicError, "Need #{level_number} user level" unless @user.level >= level_number
			raise LogicError, "Energy already ended" unless @user.debit_energy()
		end
		@response['user'] = @user.to_json
	end
end
