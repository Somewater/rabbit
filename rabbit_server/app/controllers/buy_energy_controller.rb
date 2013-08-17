class BuyEnergyController < BaseUserController

	def process
		total_price = PUBLIC_CONFIG['ENERGY_COST'].to_i

		raise LogicError, "Not enough money to purchase" if total_price > @user.money

		@user.money -= total_price
		@user.gain_energy()

		@response['success'] = 1
		@response['user'] = @user.to_json
	end

end