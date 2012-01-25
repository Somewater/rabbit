class Conf < ActiveRecord::Base

	@@json_cache = nil

	def self.[](name)
		self.by_name(name)
	end

	def self.by_name(name)
		Conf.find(:first, :conditions => ['name = ?', name.to_s])
	end

	def self.all_head()
		Conf.all(:order => 'name', :conditions => 'visible = TRUE')
	end

	def self.to_json
		unless @@json_cache
			hash = {}
			self.all_head.each{|c| hash[c.name] = c.value}
			@@json_cache = JSON.fast_generate(hash)
		end
		@@json_cache
	end

	def self.clear_cache()
		@@json_cache = nil
	end
end