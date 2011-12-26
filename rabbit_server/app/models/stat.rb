class Stat < ActiveRecord::Base
	
	establish_connection(DB_CONF['stat']) if(APP_ENV != 'test')
	
	# set value
	def self.[]=(name, value)
	  # only for MySQL
		self.count_by_sql(["INSERT INTO stats SET name=?, time=#{self.time}, value=? ON DUPLICATE KEY UPDATE value=?",name,value,value])
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
		# only for MySQL
		self.count_by_sql(["INSERT INTO stats SET name=?, time=#{self.time}, value=? ON DUPLICATE KEY UPDATE value=value+?",name,diff,diff])
	end
	
	private
	def self.time
		ts = Application.time.to_i
		ts - (ts % 1800)
	end
end

module ActiveRecord
  module ConnectionAdapters
    class Mysql2Adapter
      def select(sql, name = nil)
        n = execute(sql, name)
        n.each(:as => :hash) if n
      end
    end
  end
end