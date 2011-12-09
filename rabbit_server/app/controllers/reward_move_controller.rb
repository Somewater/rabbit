class RewardMoveController < BaseUserController
	# прогнать левел инстанс через server_logic и выдать ответ клиенту
	def process
		raise FormatError unless @json['reward'] && @json['reward']['id'] && @json['reward']['x'] && @json['reward']['y']

		reward = @user.rewards[ @json['reward']['id'].to_s]
		raise LogicError, "Unknown reward id #{@json['reward']['id']}" unless reward

		reward['x'] = @json['reward']['x']
		reward['y'] = @json['reward']['y']

		@response['reward'] = reward
	end
end