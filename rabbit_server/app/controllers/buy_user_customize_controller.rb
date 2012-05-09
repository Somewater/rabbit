class BuyUserCustomizeController < BaseUserController

	# купить означенные purchase, заданные в формате "roof:123,door:356"
	def process
		purchase = []
		total_price = 0
		@json['purchase'].split(',').each do |pair|
			pair = pair.split(':')
			item = ItemManager.instance.by_id(pair.last.to_i)
			raise LogicError, "Undefined item id #{pair.last.to_i}" unless item
			total_price += item[:cost].to_i
			purchase << pair
		end

		raise LogicError, "Not enough money to purchase" if total_price > @user.money

		@user.money -= total_price
		purchase.each do |pair|
			@user.set_customize(pair.first.to_s, pair.last.to_i)
		end

		@response['success'] = 1
		@response['user'] = @user.to_json
	end

end