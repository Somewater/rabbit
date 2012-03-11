class BuyUserItemController < BaseUserController

	# купить означенные purchase, заданные в формате "123:1,345:3"
	def process
		purchase = []
		total_price = 0
		@json['purchase'].split(',').each do |pair|
			pair = pair.split(':')
			item = ItemManager.instance.by_id(pair.first.to_i)
			raise LogicError, "Undefined item id #{user_item_id}" unless item
			total_price += item[:cost].to_i * pair.last.to_i
			purchase << pair
		end

		raise LogicError, "Not enough money to purchase" if total_price > @user.money

		@user.money -= total_price
		purchase.each do |pair|
			@user.add_item(pair.first.to_i, pair.last.to_i)
		end

		@response['success'] = 1
		@response['user'] = @user.to_json
	end

end