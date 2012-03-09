# генерация статического конфига (в текстовом вформатеиде)
module ConfigGenerator

	ITEMS_KEY = 'ITEMS'

	@@txt_cache = nil

	def self.generate
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
		end
		@@txt_cache
	end

	def self.clear_cache
		@@txt_cache = nil
	end
end