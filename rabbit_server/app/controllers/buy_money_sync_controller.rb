class BuyMoneySyncController < BaseUserController

	# синхронная покупка кругликов, входящий запрос {money: 10, netmoney:1}
	def process
		money_quantity = @json['money'].to_i
		netmoney_quantity = @json['netmoney'].to_i
		netmoney_to_money = CONFIG[@user.api.name.to_s]["netmoney_to_money"]
		raise AuthError, "Current net unsupport billing" unless netmoney_to_money
		raise LogicError, "Unsupported price" if netmoney_to_money[netmoney_quantity] != money_quantity

		transaction = Transaction.create_from(@user, money_quantity, netmoney_quantity)
		transaction.save

		Application.logger.warn("Pay ##{transaction.id} started: uid=#{@user.uid}, net=#{@user.net}, #{netmoney_quantity}=>#{money_quantity}")
		pay_result = @user.api.pay(@user, netmoney_quantity)
		transaction << 'exec'
		unless(pay_result) # pay не выдал ошибку
			Application.logger.warn("Payment ##{transaction.id} success")
			@user.money += money_quantity
			@user.save
			@response['user_money'] = @user.money
			@response['success'] = true
			transaction << 'success'
		else
			Application.logger.warn("Payment ##{transaction.id} error: #{pay_result.to_s}")
			@response['error'] = pay_result.to_s
			transaction << 'error'
		end
		transaction.save
	end

end
