class LogsAdminController < AdminController::Base

	LOGS_PATH = '/admin/logs'

	def check_permissions()
		raise AuthError, "Illegal operation" unless @admin_user.can?(AdminUser::PERMISSION_LOG_VIEW)
	end

	def call
		result = "<h1><a href='#{LOGS_PATH}'>LOGS</a></h1><br><p><a href='#{LOGS_PATH}?delete_all=1'>[DELETE ALL]</a></p>"
		if(request['delete_all'])
			Dir["#{ROOT}/logs/*"].each do|log|
				File.open(log,'w') do |f|
					f.truncate(0)
				end
			end
		end
		if(request['delete'])
			File.open("#{ROOT}/logs/#{request['delete']}",'w') do |f|
				f.truncate(0)
			end
		end
		Dir["#{ROOT}/logs/*"].each do|log|
			log = File.basename(log)
			result << '<br>' << tag("a", :href => "#{LOGS_PATH}?filename=#{log}", :value => log) <<
					'&nbsp;' << tag("a", :href => "#{LOGS_PATH}?delete=#{log}", :value => '[delete]')
		end
		if(request['filename'])
			require 'ansitags'
			result << "<br><br><center><h2>#{request['filename']}</h2></center><br><pre>"
			filecontent = File.read("#{ROOT}/logs/#{request['filename']}").encode('utf-8')
			filecontent = filecontent.ansi_to_html rescue filecontent
			result << filecontent
		end
		result
	end
end
