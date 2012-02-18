# генерация статического конфига (в текстовом вформатеиде)
module ConfigGenerator

	@@txt_cache = nil

	def self.generate
		unless @@txt_cache
			@@txt_cache = ''

			# прочитать конфигурацию из базы
			Conf.all_head.each do|c|
				@@txt_cache << "#{c.name}=#{c.value}\n\n"
			end

			# прочитать конфигурацию статических файлов
			customizer = []
			StaticManager.instance.each do |v|
				customizer << v
			end
			@@txt_cache << "#{StaticManager::CUSTOMIZES}=#{JSON.fast_generate(customizer)}\n\n"
		end
		@@txt_cache
	end

	def self.clear_cache
		@@txt_cache = nil
	end
end