class Story < ActiveRecord::Base
	set_table_name :stories

	def to_xml
"<story id=\"#{id}\">
	<number>#{number}</number>
	<name>#{name}</name>
	<description>#{description}</description>
	<image>#{image}</image>
	<start_level>#{start_level}</start_level>
	<end_level>#{end_level}</end_level>
	<enabled>#{enabled}</enabled>
</story>"
	end

	def self.by_level_number(number)
		Story.find(:first, :conditions => ['number = ?', number.to_i])
	end

	def self.all_head()
		Story.all(:order => 'number')
	end
end