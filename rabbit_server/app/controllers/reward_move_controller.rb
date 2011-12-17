class RewardMoveController < BaseUserController
	# прогнать левел инстанс через server_logic и выдать ответ клиенту
	def process
		raise FormatError, "Field 'rewards' not assigned" unless @json['rewards'] || @json['rewards'].size == 0

		moved_rewards = []
		@json['rewards'].each do |moved_reward|
			reward = @user.rewards[ moved_reward['id'].to_s]
			raise LogicError, "Unknown reward id #{moved_reward['id']}" unless reward

			reward['x'] = moved_reward['x']
			reward['y'] = moved_reward['y']
			moved_rewards << moved_reward
		end

		@response['rewards'] = moved_rewards
	end
end