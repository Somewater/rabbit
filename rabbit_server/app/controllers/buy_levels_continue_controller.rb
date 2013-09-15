# ведет учет траты энергии на неуспешное прохождение уровня
class BuyLevelsContinueController < BaseUserController

	# прогнать левел инстанс через server_logic и выдать ответ клиенту
	def process
		flag = @json['flag']
		price = 0
		if flag == 'carrot'
			price = PUBLIC_CONFIG['CONTINUE_CARROTS_COST']
		elsif flag == 'life'
			price = PUBLIC_CONFIG['CONTINUE_LIFE_COST']
		elsif flag == 'time'
			price = PUBLIC_CONFIG['CONTINUE_TIME_COST']
		end
		raise "Wrong flag #{flag}" if price == 0
		need = price - @user.money
		raise "Need #{need} money" if need > 0
		@user.money -= price
		@response['money'] = @user.money
		@response['success'] = true
	end
end
