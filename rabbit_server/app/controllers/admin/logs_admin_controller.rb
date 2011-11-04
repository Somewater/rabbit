class LogsAdminController < AdminController::Base

	LOGS_PATH = '/admin/logs'

	def call
		result = ''
		Dir["#{ROOT}/logs/*"].each do|log|
			log = File.basename(log)
			result << '<br>' << tag("a", :href => "#{LOGS_PATH}?filename=#{log}", :value => log)
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