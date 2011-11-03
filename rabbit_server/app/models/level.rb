class Level < ActiveRecord::Base
	attr_accessor :head # является ли левел ведущим (т.е. именно он применяется при генерации xml)

	def to_xml
		formatted_conditions = ''
		conditions.each_line{|line| formatted_conditions += (formatted_conditions.size>0 ? "\t#{line}" : line)} if conditions

		formatted_group = ''
		group.each_line{|line| formatted_group += (formatted_group.size>0 ? "\t#{line}" : line)} if group

"<level id=\"#{id}\" version=\"#{version}\">
	<description>#{description}</description>
	<number>#{number}</number>
	<author>#{author}</author>
	<width>#{width}</width>
	<height>#{height}</height>
	<image>#{image}</image>
	#{formatted_conditions}
	#{formatted_group}
</level>"
	end

	# возвратить все "ведущие" уровни
	def self.all_head
		added = {}
		result = []
		levels = Level.all(:order => 'number, version DESC', :conditions => 'enabled = TRUE AND visible = TRUE')
		levels.each do |lvl|
			unless added[lvl.number]
				result << lvl
				added[lvl.number] = true
			end
		end
		result
	end
end