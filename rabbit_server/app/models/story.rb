class Story < ActiveRecord::Base
	set_table_name :stories

	def self.by_level_number(number)
		Story.find(:first, :conditions => ['number = ?', number.to_i])
	end
end