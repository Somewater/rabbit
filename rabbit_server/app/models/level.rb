class Level < ActiveRecord::Base
	attr_accessor :head # является ли левел ведущим (т.е. именно он применяется при генерации xml)

	def to_xml
		formatted_conditions = ''
		conditions.each_line{|line| formatted_conditions += (formatted_conditions.size>0 ? "\t#{line}" : formatted_conditions)} if conditions

		formatted_group = ''
		group.each_line{|line| formatted_group += (formatted_group.size>0 ? "\t#{line}" : formatted_group)} if group

"<level id=\"#{id}\" version=\"#{version}\">
	<description>#{description}</description>
	<number>#{number}</number>
	<author>#{author}</author>
	<width>#{width}</width>
	<height>#{height}</height>
	#{formatted_conditions}
	#{formatted_group}
</level>"
	end
end