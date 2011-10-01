class ErrorsController < Application
	def call request
		res = "<html><body>"

		Application.connect_to "stat" do
			errors = Error.find(:all)

			errors.each_with_index do |e, index|
				res += "<div style=\"background: #{e.resolved == 0 ? '#CCFFFF' : '#FFCCFF'}\"><h3>#{e.title}  (#{e.resolved ? 'resolved!' : 'unresolved'})</h3><h4>Content:</h4>#{e.content}<h4>Resolution:</h4><pre>#{e.resolution}</pre></div>"
			end
		end

		"#{res}</body></html>"
	end
end
