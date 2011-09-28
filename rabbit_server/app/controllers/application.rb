class Application
	class << self

	def logger
		unless @logger
			@logger = Logger.new(DEVELOPMENT ? File.join(ROOT, %w{ logs development.log}) : STDOUT)
			if DEVELOPMENT
			  @logger.level = Logger::INFO
			else
			  @logger.level = Logger::DEBUG
			end
			@logger.formatter = Logger::Formatter.new
		end
		@logger
    end

		def call(env)
			begin
				request = Rack::Request.new(env)
				[200, { "Content-Type" => "text/html" }, [_call(request)]]
			rescue =>ex
				[200, { "Content-Type" => "text/html" }, DEVELOPMENT ? \
							["E_FATAL<pre>#{ex} \n#{ex.backtrace.join(?\n)}"]	: ["E_FATAL"]]
			end
		end

		private
		def _call(request)
			method = request.path
			method = method[1, method.size - 1]

			case method
				when "version"
					"0.0.0"
				when /^ls/
					`echo "<pre>" && ls -la`
				when "test"
					require "test.rb"
					Test.call request
				when "calc"
					time = Time.new
					i = 0
					n = ""
					while i < 100
						n += i.to_s
						i += 1
					end
					"time=#{(Time.new - time).to_f}"
				else
					Hello.new.call request
			end

		end
	end
end
