class Level < ActiveRecord::Base
	attr_accessor :head # является ли левел ведущим (т.е. именно он применяется при генерации xml)

	def to_xml
		formatted_conditions = ''
		conditions.each_line{|line| formatted_conditions += "\t#{line}"} if conditions

		formatted_group = ''
		group.each_line{|line| formatted_group += "\t#{line}"} if group

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