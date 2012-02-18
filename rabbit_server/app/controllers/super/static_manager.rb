class StaticManager

	CUSTOMIZES = 'CUSTOMIZES'

	@@instance = nil

	def initialize
		read_data
	end

	def self.instance
		unless @@instance
			@@instance = StaticManager.new
		end
		@@instance
	end

	def by_id(id)
		@items_by_id[id.to_i]
	end

	def by_name(name)
		@items_by_name[name.to_s]
	end

	def each
		if block_given?
			@items_by_id.each do |id, value|
				yield(value)
			end
		end
	end

	private
	def read_data
		@items_by_name = {}
		@items_by_id = {}

		#todo: другие файлы конфигов тоже парсить тут
		yaml = YAML.load(File.read("#{CONFIG_DIR}/hole_customize.yml"))
		yaml.each do |name, value|
			id = value['id'].to_i
			if(id > 0)
				raise FormatError, "Dublicate ids #{id}: #{name} and #{@items_by_id[id][:name]}" if @items_by_id[id]
				value.symbolize_keys!
				@items_by_name[name.to_s] = value
				@items_by_id[id] = value
				value[:name] = name
			end
		end
	end
end