# генерация статического конфига (в текстовом вформатеиде)
module ConfigGenerator

	ITEMS_KEY = 'ITEMS'

	@@txt_cache = nil
	@@net_txt_cache = {}

	def self.generate(net)
		net = net.to_i

		unless @@txt_cache
			@@txt_cache = ''

			# прочитать конфигурацию из базы
			Conf.all_head.each do|c|
				@@txt_cache << "#{c.name}=#{c.value}\n\n"
			end

			# прочитать конфигурацию статических файлов
			items = []
			ItemManager.instance.each do |v|
				items << v
			end
			@@txt_cache << "#{ITEMS_KEY}=#{JSON.fast_generate(items)}\n\n"
			PUBLIC_CONFIG.each do |k,v|
				@@txt_cache << "#{k}=#{v}\n\n"
			end
		end
		@@net_txt_cache[net] = generate_net_config(net) unless @@net_txt_cache[net]
		@@txt_cache + @@net_txt_cache[net]
	end

	def self.clear_cache
		@@txt_cache = nil
		@@net_txt_cache = {}
	end

	def self.generate_net_config(net)
		response = ''
		if net == 2
			# специально для Вконтакт
			response << "NETMONEY_TO_MONEY=#{CONFIG['vkontakte']['netmoney_to_money'].to_json}\n\n"
		elsif net == 3
			# с любовью для Mail.Ru
			response << "NETMONEY_TO_MONEY=#{CONFIG['mailru']['netmoney_to_money']}\n\n"
		end
		response
	end
end