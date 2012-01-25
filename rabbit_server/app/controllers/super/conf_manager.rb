class ConfManager

	@@instance = nil

	def initialize
		read_data
	end

	def self.instance
		unless @@instance
			@@instance = ConfManager.new
		end
		@@instance
	end

	def self.[](name)
		instance[name]
	end

	def [](name)
		@confs_by_name[name.to_sym]
	end

	def clear_cache()
		read_data()
	end

	private
	def read_data()
		@confs_by_name = {}
		Conf.all_head.each{|c| @confs_by_name[c.name.to_sym] = c.value}
	end
end