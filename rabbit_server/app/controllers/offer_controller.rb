# контролирует сбор офферов
class OfferController < BaseUserController

	include RequestSecurity

	# инкрементить счетчик тьюториала, делать проверки на некорректность присваемого значения
	def process
		offers = @json['offers'] # на входе получает массив id офферов, если один из них некорректен, остальные всё таки применяются
		offers_added = []
		offers.each do |offer_id|
			offer = OfferManager.instance.get_by_id(offer_id)
			if(offer && !@user.offer_instances[offer.id])
				@user.add_offer_instance(offer)
				offers_added << offer_id
			end
		end
		raise LogicError, "All offers not approved" if offers_added.size == 0
		@response['offers_added'] = offers_added
	end
end