# encoding: utf-8

require_relative 'net/vk_api'
class RabbitVkApi < VkApi
	def get_item_info item, lang, test
		item = item.to_i
		item = item - 100 if item > 100 # фикс для введения в действие после выставление expiration
		money = CONFIG[self.name.to_s]["netmoney_to_money"][item.to_i]
		{:title => "#{money} кругликов",
		 :photo_url => "http://krolgame.static1.evast.ru/VK/money2/money_#{money}.jpg",
		 :price => item.to_i,
		 :expiration => 7200} # 2 hours
	end

	# Осуществить покупку товара
	# @param item:String идентификатор товара
	# @return Int уникальный номер заказа в системе
	def order_status_change receiver_id, item, net_price, test
		user = User.find_by_uid(receiver_id)
		netmoney_to_money = CONFIG[self.name.to_s]["netmoney_to_money"]
		raise "Current net unsupport billing" unless netmoney_to_money && netmoney_to_money[net_price.to_i]
		money = netmoney_to_money[net_price.to_i]
		t = Transaction.create_from(user, money, net_price)
		t.test = test
		t.save
		user.money += money
		user.save
		t.id
	end

	def on_event(uid, name, params = nil)
		if name == 'level'

			self.secure_vk.secure.setUserLevel(uid, params[:level]) rescue nil
		end
	end
end

NetApi.register(RabbitVkApi)