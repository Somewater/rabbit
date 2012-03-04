class TopManager

	TOP_NAMES = [:stars, :level]

	@@instance = nil

	# Содержит кэш заранее просчитанных uid-ов (и результата)
	#
	# tops[<net>][<top_name>] = [ ... ] - массив хэшей {:uid, :value} отсортированные в порядке возрастания value
	#
	attr_reader :tops
	attr_reader :top_version

	def initialize
		@top_version = 0
		read_files
	end

	def self.instance
		unless @@instance
			@@instance = TopManager.new
		end
		@@instance
	end

	def get_tops(net, top_name)
		return [] unless @tops[net.to_i]
		return [] unless @tops[net.to_i][top_name.to_sym]
		@tops[net.to_i][top_name.to_sym]
	end

	# пересчитать всё и записать в файлы
	def write_files
		t = Time.new.to_f
		top_cache_path = "#{TMP_DIR}/top_cache.yml"
		@tops = {}
		User.find(:all).each do |user|
			@tops[user.net] = {} unless @tops[user.net]
			net_tops = @tops[user.net]

			# обрабатываем каждый построитель топов
			TOP_NAMES.each do |top_name|
				top = net_tops[top_name]
				unless top
					top = []
					net_tops[top_name] = top
				end
				TopsChecker.checkTop(top_name, user, top)
			end
		end
		File.open(top_cache_path, 'w') do |file|
			file.write(YAML.dump(@tops))
		end
		@top_version = File.stat(top_cache_path).mtime.to_i
		puts "TIME #{(Time.new.to_f - t)}"
	end

private
	def read_files
		top_cache_path = "#{TMP_DIR}/top_cache.yml"
		if File.exist?(top_cache_path)
			@tops = YAML.load(File.read(top_cache_path))
			@top_version = File.stat(top_cache_path).mtime.to_i
		end
		@tops
	end
end

module TopsChecker

	MAX_USERS = 200 # делаем запас в 2 раза (фактически используем только 100), чтобы случаи множестенных одинаковых значений корректно обрабатыались

	#
	# top_name - имя рассматриваемого топа (тип топа)
	# user - юзер, который рассматривается как претендент для внесения в топ
	# cache - массив Объектов Tops, уже внесенных в список, начиная от самого "некрутого"
	#
	def self.checkTop(top_name, user, cache)
		uid = user.uid
		value = 0.0

		case top_name.to_sym
			when :stars
				value = user.stars.to_f + 0.01 * user.level
			when :level
				value = user.level.to_f + 0.01 * user.stars
			else
				raise FormatError, "Undefined top name: #{top_name}"
		end

		if cache.length == 0
			cache << {:uid => uid, :value => value}
		else
			#
			index = cache.find_index do |obj|
				obj[:value] > value # первый объект в кэше, который выше текущего
			end

			if index.nil?
				cache << {:uid => uid, :value => value}
			elsif index > 0 || cache.length < MAX_USERS
				# вставить на заслуженное место, куда то в середину массива
				cache.insert(index, {:uid => uid, :value => value})
			end

			# удаляем неудачников
			cache.shift if cache.length > MAX_USERS
		end
	end
end