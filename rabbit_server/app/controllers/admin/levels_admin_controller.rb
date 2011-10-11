require "erb"
require "cgi"

class LevelsAdminController < AdminController::Base

	LEVELS_PATH = '/admin/levels'
	COLORS = ['FFEEEE', 'EEFFEE', 'DDEEFF', 'FFDDEE', 'DDFFEE','DDDDFF', 'FFDDFF', 'DDFFFF', 'FFFFDD', 'CDCDFF']

	def self_binding
		binding
	end

	def call
		res = ""
		@showed = nil

		case @request['act']
			when 'show'
				@showed = Level.find(@request['id'])
			when 'enable'
				lvl = Level.find(@request['id'])
				lvl.enabled = true
				lvl.save
			when 'disable'
				lvl = Level.find(@request['id'])
				lvl.enabled = false
				lvl.save
			when 'head'
				head_level(@request['id'])
		end

		@levels = Level.all(:order => 'number, version')

		# определяем head
		head_levels_arr = LevelsAdminController.all_head.map(&:id)
		@levels.each do |lvl|
			lvl.head = head_levels_arr.index(lvl.id)
		end

		template <<-EOF
<h1><a href='<%= LEVELS_PATH %>'>LEVELS</a></h1>
<% @levels.each_with_index do |level, index| %>
<div style="background: #<%= COLORS[level.number % 10] %>">
	<p><%=level.head ? '<b>' : nil%><a href='<%= LEVELS_PATH %>?id=<%= level.id%>&act=show'>level #<%= level.number %> </a><small><i>(version=<%= level.version %>, id=<%= level.id %>)</i></small>
<a href='<%= LEVELS_PATH %>?id=<%= level.id%>&act=<%= level.enabled ? 'disable' : 'enable' %>'><%= level.enabled ? 'disable' : 'enable' %></a>
<% unless level.head %>
	<a href='<%= LEVELS_PATH %>?id=<%= level.id%>&act=head'>HEAD</a>
<% end %>
	<%=level.head ? '</b>' : nil%></p>
	<% if @showed && level.id == @showed.id %>
		<p><small><i><%= level.description %></i></small></p>
		<p>GROUP:<br><small><pre><%= CGI::escapeHTML(level.group || '') %></pre></small></p>
		<p>CONDITIONS:<br><small><pre><%= CGI::escapeHTML(level.conditions || '') %></pre></small></p>
	<% end %>
</div>
<% end %>
		EOF

	end

	# генерировать содержание файла левелов (наиболее новой версии, в соответствии с БД)
	def self.generate_xml_file
		head_levels = LevelsAdminController.all_head
		content = head_levels.map{|lvl| lvl.to_xml }
		[
		 200,
		 {"Content-Type" => "text/xml; charset=UTF-8"},
		 "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<levels version=\"0\">\n#{content.join("\n")}\n</levels>"
		]
	end

	private
		def head_level(level_id)
			lvl = Level.find(level_id)
			lvl.enabled = true
			lvl.save

			family = Level.find(:all, :order => "version", :conditions => "number = #{lvl.number} AND version > #{lvl.version}")

		    family.each {|l| l.enabled = false; l.save}
		end

		# возвратить все "ведущие" уровни
		def self.all_head
			added = {}
			result = []
			levels = Level.all(:order => 'number, version DESC', :conditions => 'enabled = TRUE')
			levels.each do |lvl|
				unless added[lvl.number]
					result << lvl
					added[lvl.number] = true
				end
			end
			result
		end
end