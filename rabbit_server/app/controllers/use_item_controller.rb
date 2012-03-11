class UseItemController < BaseUserController

	# просто списывает у юзера указанный айтем, выдает ошибку, если такого айтема нет
	def process
		raise FormatError, "Item id not assigned" unless @json['item_id']
		@user.delete_item(@json['item_id'].to_i)

		@response['success'] = true
		@response['quantity'] = @user.items[@json['item_id'].to_i]
	end
end