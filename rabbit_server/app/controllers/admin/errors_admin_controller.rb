class ErrorsAdminController < AdminController::Base
	ERROR_PATH = '/admin/errors'
	# CREATE TABLE `errors` (
	#  `id` int(11) NOT NULL AUTO_INCREMENT,
	#  `title` varchar(255) DEFAULT NULL,
	#  `content` text,
	#  `images` varchar(255) DEFAULT NULL,
	#  `resolution` text,
	#  `resolved` tinyint(3) DEFAULT '0',
	#  PRIMARY KEY (`id`)
	# ) ENGINE=MyISAM AUTO_INCREMENT=99 DEFAULT CHARSET=utf8

	def call
		res = ""
		error = {}

		# act = new, edit, resolve, unresolve, check, delete
		act = request['act']

		case act
			when "new"
				if request['title'] && request['title'].length > 3
					error = Error.new
					error.attributes = {:title => request['title'], :content => request['content'],
											:resolution => request['resolution'], :resolved => 0}
					error.save
					error = {}
				else
					return "<html></body>ERROR: very short title \"#{request['title']}\"<br><a href='#{ERROR_PATH}'>back</a></body></html>"
				end
			when "edit"
				error = Error.find(request['id']) if request['id'] && request['id'].length > 0
				if request.post?
					error.attributes = {:title => request['title'], :content => request['content'],
										:resolution => request['resolution'], :resolved => request['resolved']}
					error.save
					act = 'new'
					error = {}
				end
			when "resolve"
				error = Error.find(request['id'])
				error.resolved = 1
				error.save
				error = {}
			when "unresolve"
				error = Error.find(request['id'])
				error.resolved = 0
				error.save
				error = {}
			when "check"
				error = Error.find(request['id'])
				error.resolved = 2
				error.save
				error = {}
			when "delete"
				error = Error.find(request['id'])
				error.delete
				error = {}
		end

		errors = Error.find(:all, :order => "resolved")

		errors.each_with_index do |e, index|
			#error = e if e['id'] == request['id']
			url = ERROR_PATH + "?id=" + e['id'].to_s
			resolved = e.resolved || 0
			res += "<div style=\"background: #{resolved == 2 ? '#EEEEEE' : (resolved == 1 ? '#CCFFCC' : '#FFCCFF')}\"><h3>
					<a href='#{url}&act=edit'>#{e.title ? e.title : nil}</a>&nbsp;&nbsp;&nbsp;&nbsp;<small>#{
						(["<a href='#{url}&act=resolve'>resolve :)</a>","<a href='#{url}&act=check'>check :)</a>&nbsp;&nbsp;&nbsp;&nbsp;<a href='#{url}&act=unresolve'>unresolve :(</a>","<a href='#{url}&act=delete'>delete :)</a>"])[resolved] }
					</small></h3><h4>Content:</h4>#{e.content ? e.content : nil}<h4>Resolution:</h4><i>#{e.resolution ? e.resolution : nil}</i><h4>Images:</h4>#{e.images}</div>"
		end

		form = create_form([{:value => error['title']	, :name => 'title', :title => 'Title', :type => 'input'},
							{:value => error['content']	, :name => 'content', :title => 'Content', :type => 'textarea'},
							{:value => error['resolution']	, :name => 'resolution', :title => 'Resolution', :type => 'textarea'},
							{:value => ( act == 'edit' ? 'Save' : 'Create error'), :type => 'submit'}
						   ], act, error)
		"<html><head></head><body style='font-size: 14px;'>#{form}#{res}</body></html>"
	end

private
	def create_form(inputs, act, error = nil)
		"<p><h1><a href='#{ERROR_PATH}'>ERROR TRACKER #2</a></h1></p>
			<p><form width='100%' method='post'>
			<table width='100%'>
				#{ inputs.map{|input|
					"<tr width='100%'>
					<td valign='top' width='200'>#{input[:title]}</td>
					<td width=100%>
						<#{input[:type] == 'textarea' ? 'textarea rows="6" cols="80"' : 'input'} size='60' type='#{input[:type]}' name='#{input[:name]}' value='#{input[:type] == 'textarea' ? nil : input[:value]}'>#{input[:type] == 'textarea' ? input[:value] : nil}</#{input[:type] == 'textarea' ? 'textarea' : 'input'}>
					</td>
					</tr>" }.join("\n")
				}
				<input type='hidden' name='act' value='#{(act || 'new')}'></input>
				<input type='hidden' name='id' value='#{error['id']}'></input>
				#{
					act == 'edit' ?
					"<tr width='100%'><td></td><td width='100%'>
					<input type='radio' #{(error && error['resolved'] == 0) || (!error) ? 'cheched' : nil} name='resolved' value='0'>Unresolved&nbsp;</input>
					<input type='radio' #{error && error['resolved'] == 1 ? 'cheched' : nil} name='resolved' value='1'>Resolved&nbsp;</input>
					<input type='radio' #{error && error['resolved'] == 2 ? 'cheched' : nil} name='resolved' value='2'></input>Checked
					</td></tr>"
					 : nil
					}
			</table>
		</form></p><p></p>"
	end
end
