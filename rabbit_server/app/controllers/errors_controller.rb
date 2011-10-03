# encoding: utf-8
class ErrorsController < Application

	ERROR_PATH = '/errors'
	# CREATE TABLE `errors` (
	#  `id` int(11) NOT NULL AUTO_INCREMENT,
	#  `title` varchar(255) DEFAULT NULL,
	#  `content` text,
	#  `images` varchar(255) DEFAULT NULL,
	#  `resolution` text,
	#  `resolved` tinyint(3) DEFAULT '0',
	#  PRIMARY KEY (`id`)
	# ) ENGINE=MyISAM AUTO_INCREMENT=99 DEFAULT CHARSET=utf8

	def call request
		res = ""
		error = {}

		# act = new, edit, resolve, unresolve, check, delete
		act = request['act']

		Application.connect_to "stat" do
			case act
				when "new"
					if request['title'] && request['title'].length > 3
						error = Error.new
						error.attributes = {:title => request['title'], :content => request['content'],
												:resolution => request['resolution'], :resolved => 0}
						error.save
						error = {}
					end
				when "edit"
					error = Error.find(request['id']) if request['id'] && request['id'].length > 0
					if request.post?
						error.attributes = {:title => request['title'], :content => request['content'],
											:resolution => request['resolution'], :resolved => request['resolved']}
						error.save
						act = 'new'
						error = {}
					else
						error.title = error.title.force_encoding('UTF-8')
						error.content = error.content.force_encoding('UTF-8')
						error.resolution = error.resolution.force_encoding('UTF-8')
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
				res += "<div style=\"background: #{resolved == 2 ? '#EEEEEE' : (resolved == 1 ? '#CCFFFF' : '#FFCCFF')}\"><h3>
						<a href='#{url}&act=edit'>#{e.title}</a>&nbsp;&nbsp;&nbsp;&nbsp;<small>#{
							(["<a href='#{url}&act=resolve'>исправить :)</a>","<a href='#{url}&act=check'>проверить :)</a>&nbsp;&nbsp;&nbsp;&nbsp;<a href='#{url}&act=unresolve'>пересмотр :(</a>","<a href='#{url}&act=delete'>удалить :)</a>"])[resolved] }
						</small></h3><h4>Описание:</h4>#{e.content.force_encoding('UTF-8')}<h4>Ответ:</h4><pre>#{e.resolution.force_encoding('UTF-8')}</pre><h4>Картинки:</h4>#{e.images}</div>"
			end
		end

		form = create_form([{:value => error['title']	, :name => 'title', :title => 'Заголовок', :type => 'input'},
							{:value => error['content']	, :name => 'content', :title => 'Описание', :type => 'textarea'},
							{:value => error['resolution']	, :name => 'resolution', :title => 'Описание', :type => 'textarea'},
							{:value => ( act == 'edit' ? 'Сохранить' : 'Создать ошибку'), :type => 'submit'}
						   ], act, error)
		[200, {"Content-Type" => "text/html; charset=UTF-8"}, "<html><head></head><body>#{form.force_encoding('UTF-8')}#{res.force_encoding('UTF-8')}</body></html>"]
	end
	
	def create_form(inputs, act, error = nil)
		"<p><form width='100%' method='post'>
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
					<input type='radio' #{(error && error['resolved'] == 0) || (!error) ? 'cheched' : nil} name='resolved' value='0'>Не исправлена&nbsp;</input>
					<input type='radio' #{error && error['resolved'] == 1 ? 'cheched' : nil} name='resolved' value='1'>Исправлена&nbsp;</input>
					<input type='radio' #{error && error['resolved'] == 2 ? 'cheched' : nil} name='resolved' value='2'></input>Проверена
					</td></tr>"
					 : nil
					}
			</table>
		</form></p><p></p>"
	end
end
