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
			when 'delete_request'
				@sure = "delete current level(id=#{@request['id']})"
				@yes = "#{LEVELS_PATH}?id=#{@request['id']}&act=delete"
				@no = "#{LEVELS_PATH}"
				return html{template File.read("#{TEMPLATE_ROOT}/admin/levels_admin_dialog.erb")}
			when 'delete'
				lvl = Level.find(@request['id'], :conditions => 'visible = TRUE')
				lvl.visible = false
				lvl.save
			when 'delete_all_request'
				@sure = "delete current level(id=#{@request['id']}) and older levels"
				@yes = "#{LEVELS_PATH}?id=#{@request['id']}&act=delete_all"
				@no = "#{LEVELS_PATH}"
				return html{template File.read("#{TEMPLATE_ROOT}/admin/levels_admin_dialog.erb")}
			when 'delete_all'
				delete_current_and_anchestors(@request['id'])
			when 'head'
				head_level(@request['id'])
		end

		@levels = Level.all(:order => 'number, version', :conditions => (@request['hidden'] ? nil : 'visible = TRUE'))

		# определяем head
		head_levels_arr = LevelsAdminController.all_head.map(&:id)
		@levels.each do |lvl|
			lvl.head = head_levels_arr.index(lvl.id)
		end

		template File.read("#{TEMPLATE_ROOT}/admin/levels_admin_show.erb")
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
			lvl.visible = true
			lvl.save

			Level.update_all('enabled = FALSE', "number = #{lvl.number} AND version > #{lvl.version} AND visible = TRUE")
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

		def delete_current_and_anchestors(level_id)
		  	lvl = Level.find(level_id)
			lvl.visible = false
			lvl.save

			Level.update_all('visible = FALSE', "number = #{lvl.number} AND version < #{lvl.version}")
		end
end