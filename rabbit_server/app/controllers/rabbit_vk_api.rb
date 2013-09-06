# encoding: utf-8

require_relative 'net/vk_api'
class RabbitVkApi < VkApi
	def get_item_info item, lang
		money = CONFIG[self.name.to_s]["netmoney_to_money"][item.to_i]
		{:title => "Круглики", :price => item.to_i}
	end

	# Осуществить покупку товара
	# @param item:String идентификатор товара
	# @return Int уникальный номер заказа в системе
	def order_status_change receiver_id, item, net_price
		user = User.find_by_uid(receiver_id)
		netmoney_to_money = CONFIG[self.name.to_s]["netmoney_to_money"]
		raise "Current net unsupport billing" unless netmoney_to_money && netmoney_to_money[net_price.to_i]
		money = netmoney_to_money[net_price.to_i]
		t = Transaction.create_from(user, money, net_price)
		t.save
		user.money += money
		user.save
		t.id
	end
end

NetApi.register(RabbitVkApi)