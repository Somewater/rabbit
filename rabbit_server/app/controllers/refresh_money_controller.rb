class RefreshMoneyController < BaseUserController

	# синхронная покупка кругликов, входящий запрос {money: 10, netmoney:1}
	def process
		@response['user_money'] = @user.money
		@response['success'] = true
	end

end
