# контролирует сбор офферов
class OfferController < BaseUserController

	include RequestSecurity

	# инкрементить счетчик тьюториала, делать проверки на некорректность присваемого значения
	def process
		offers = @json['offers'] # на входе получает массив id офферов, если один из них некорректен, остальные всё таки применяются
		offers_added = []
		prize_offer_types = []
		offers.each do |offer_id|
			offer = OfferManager.instance.get_by_id(offer_id)
			if(offer && !@user.offer_instances[offer.id])
				@user.add_offer_instance(offer)
				offers_added << offer_id
				prize_offer_types << offer.type if @user.get_offers_by_type(offer.type) == self.prize_quantity_by_type(offer.type)
			end
		end
		raise LogicError, "All offers not approved" if offers_added.size == 0
		@response['offers_added'] = offers_added

		if prize_offer_types.size > 0
			@response['prize_offer_types'] = []
			prize_offer_types.uniq.each do |type|
				self.give_prize_by_type(type)
				@response['prize_offer_types'] << type
			end
			@response['user'] = @user.to_json
		end

		@response['success'] = 1
	end

	def prize_quantity_by_type(type)
		20
	end

	def give_prize_by_type(type)
		if type == 0
			@user.add_item(ItemManager.instance.by_name('powerup_protection')[:id])
			@user.add_item(ItemManager.instance.by_name('powerup_speed')[:id])
		elsif type == 1
			@user.add_item(ItemManager.instance.by_name('pirate_door')[:id])
			@user.add_item(ItemManager.instance.by_name('pirate_roof')[:id])
			@user.set_customize('roof', ItemManager.instance.by_name('pirate_roof')[:id])
			@user.set_customize('door', ItemManager.instance.by_name('pirate_door')[:id])
		elsif type == 2
			@user.money += 50
		end
	end
end