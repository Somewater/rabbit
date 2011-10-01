class ErrorsController < Application
	def call request
		res = "<html><body>"

		Application.connect_to "stat" do
			errors = Error.find(:all)

			errors.each_with_index do |e, index|
				resolved = e.resolved
				res += "<div style=\"background: #{resolved == 2 ? '#EEEEEE' : (resolved == 1 ? '#CCFFFF' : '#FFCCFF')}\"><h3>#{e.title}  (#{resolved == 2 ? 'resolved' : (resolved == 1 ? 'review' : 'unresolved')})</h3><h4>Content:</h4>#{e.content}<h4>Resolution:</h4><pre>#{e.resolution}</pre><h4>Images:</h4>#{e.images}</div>"
			end
		end

		"#{res}</body></html>"
	end
end
