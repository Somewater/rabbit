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

		def connect_to(database, &block)
			if DB_CONF[database]
				if block_given?
					prev_db = APP_ENV
					ActiveRecord::Base.establish_connection(DB_CONF[database])
					yield
					ActiveRecord::Base.establish_connection(DB_CONF[prev_db])
				else
					ActiveRecord::Base.establish_connection(DB_CONF[database])
				end
			else
				logger.error "Try connect to \"#{database}\""
			end
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
					while i < 10000
						n += i.to_s
						i += 1
					end
					"time=#{(Time.new - time).to_f}"
				when /errors/
					ErrorsController.new.call request
				else
					Hello.new.call request
			end

		end
	end
end
