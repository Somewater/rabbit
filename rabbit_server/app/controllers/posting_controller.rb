# ведет учет прохождения уровней
class PostingController < BaseUserController

	include RequestSecurity

	# прогнать левел инстанс через server_logic и выдать ответ клиенту
	def process
		@user.postings = @user.postings + 1

		reward = ServerLogic.checkAddReward(@user, nil, nil, Reward::TYPE_POSTING, @user.postings)
		raise AuthError, 'Roll not correct' if (@user.get_roll() * 1000000).to_i != @json['roll']
		@response['reward'] = reward ? reward.to_json : nil
		@response['user'] = @user.to_json
	end
end