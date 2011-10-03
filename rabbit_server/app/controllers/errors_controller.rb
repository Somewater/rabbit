class ErrorsController < Application
	def call request
		res = ""

		Application.connect_to "stat" do
			errors = Error.find(:all, :order => "resolved")

			errors.each_with_index do |e, index|
				resolved = e.resolved
				res += "<div style=\"background: #{resolved == 2 ? '#EEEEEE' : (resolved == 1 ? '#CCFFFF' : '#FFCCFF')}\"><h3>#{e.title}  (#{resolved == 2 ? 'resolved' : (resolved == 1 ? 'review' : 'unresolved')})</h3><h4>Content:</h4>#{e.content}<h4>Resolution:</h4><pre>#{e.resolution}</pre><h4>Images:</h4>#{e.images}</div>"
			end
		end
		form = create_form([{:name => 'title', :title => 'Имя'}, {:name => 'content', :title => 'Описание'}])
		"<html><head></head><body>#{form}#{res}</body></html>"
	end
	
	def create_form(inputs)
		"<p><form>
			<table>
				<tr>
					#{ inputs.map{|input| "<td>#{input['title']}</td><td><#{input_type} name='#{input['name']}'>#{input['value']}</#{input_type}></td>" } }
				<tr>
			</table>
		</form></p><p></p>"
	end
end
