# ведет учет прохождения уровней
class LevelsController < BaseUserController

	include RequestSecurity

	# прогнать левел инстанс через server_logic и выдать ответ клиенту
	def process
		client_rewards = @json['levelInstance']['rewards']
		@json['levelInstance']['rewards'] = [] # подменяем реварды на пустой массив, чтобы ServerLogic начинал с пустого массива
		level_instance = LevelInstance.new(@json['levelInstance'])
		rewards = ServerLogic.addRewardsToLevelInstance(@user, level_instance)

		# присовить выданным ревардам координаты в соотвествии со значениями, рассчитанными на клиенте
		rewards.each do |r|
			ur = @user.rewards[r.id]
			ur['x'] = r.x
			ur['y'] = r.y
		end

		@response['levelInstance'] = level_instance.to_json
		@response['user'] = @user.to_json
	end
end