class Application

	def logger
		self.class.logger
	end

	class << self

		def logger
			unless @logger
				@logger = Logger.new( DEVELOPMENT ? $stdout : File.join(ROOT, %W{ logs #{APP_ENV}.log}))
				if PRODUCTION
				  @logger.level = Logger::DEBUG
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
					raise "Achtung!!!"
					ActiveRecord::Base.establish_connection(DB_CONF[database])
				end
			else
				logger.error "Try connect to \"#{database}\""
			end
		end

		def call(env)
			begin
				request = Rack::Request.new(env)
				response = _call(request)
				if response.is_a? Array
					response
				else
					[200, { "Content-Type" => "text/html" }, [response]]
				end
			rescue =>ex
				logger.debug "#{ex} : #{ex.backtrace.join(?\n)}"
				[200, { "Content-Type" => "text/html" }, DEVELOPMENT || true ? \
							["E_FATAL<pre>#{ex} \n#{ex.backtrace.join(?\n)}"]	: ["E_FATAL"]]
			end
		end

		private
		def _call(request)
			method = request.path
			method = method[1, method.size - 1] if method

			case method
				when "init"
					InitializeController.new(request).call
				when "levels/complete"
					LevelsController.new(request).call
				when "levels/manage"
					LevelsManageController.new(request).call
				when "levels.xml"
					LevelsAdminController.generate_xml_file
				# ADMIN AREA
				when /^admin/
					AdminController.new.call request
				when "crossdomain.xml"
					File.read("#{ROOT}/bin-debug/crossdomain.xml")
				else
					Hello.new.call request
			end

		end
	end
end
