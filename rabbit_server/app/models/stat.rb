class Stat < ActiveRecord::Base
	
	establish_connection(DB_CONF['stat']) if(APP_ENV != 'test')
	
	# set value
	def self.[]=(name, value)
		time = self.time
		stat = Stat.find(:first, :conditions => ["name=? AND time=?", name, time])
		unless stat
			stat = Stat.new(:name => name, :time => time, :value => 0)
		end
		stat.value = value
		stat.save
	end
	
	# get value
	def self.[](name)
		stat = self.find(:first, :conditions => ["name = ? AND time = #{self.time}", name])
		if(stat)
			stat.value
		else
			0
		end
	end
	
	# increment value
	def self.inc(name, diff = 1)
		time = self.time
		stat = Stat.find(:first, :conditions => ["name=? AND time=?", name, time])
		unless stat
			stat = Stat.new(:name => name, :time => time, :value => 0)
		end
		stat.value += diff
		stat.save
	end
	
	# names = array of string
	# from,to - Time
	def self.find_by_params(names, from = nil, to = nil)
		def time_to_str(time)
			i =	time.to_i
			i - (i % 7200)
		end
		time_conditions = ''
		if(from && to)
			time_conditions = ' AND time > #{time_to_str(from)} AND time < #{time_to_str(to)}'
		elsif from
			time_conditions = ' AND time > #{time_to_str(from)}'	
		elsif to
			time_conditions = ' AND time < #{time_to_str(to)}'
		end
		Stat.find(:all, :conditions => ["name in (?)#{time_conditions}", names.map{|n| "'#{n}'"}.join(',')])
	end
	
	private
	def self.time
		ts = Application.time.to_i
		ts - (ts % 7200) # stat all 2 hours
	end
end