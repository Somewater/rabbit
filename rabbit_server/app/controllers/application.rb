class Application

	def logger
		self.class.logger
	end

	cattr_accessor :controller

	class << self

		def logger
			unless @logger
				@logger = Logger.new( DEVELOPMENT ? $stdout : File.join(ROOT, %W{ logs #{APP_ENV}.log}))
				if PRODUCTION
				  @logger.level = Logger::WARN
				else
				  @logger.level = Logger::DEBUG
				end
				@logger.formatter = Logger::Formatter.new
			end
			@logger
		end

		def trace(msg)
			self.controller.trace(msg) if self.controller
		end

		def connect_to(database, &block)
      return if WIN_OS
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

		def time
			@time = Time.new unless @time
			@time
		end

		def call(env)
			@time = Time.new
			begin
				request = Rack::Request.new(env)
				response = _call(request)
				if response.is_a? Array
					response
				else
					[200, { "Content-Type" => "text/html" }, [response]]
				end
			rescue =>ex
				logger.error "#{ex} : #{ex.backtrace.join(?\n)}\n\tFROM REQUEST: #{request.path}\n#{request.params}"
				[200, { "Content-Type" => "text/html" }, DEVELOPMENT || true ? \
							["E_FATAL<pre>#{ex} \n#{ex.backtrace.join(?\n)}"]	: ["E_FATAL"]]
			end
		end

		private
		def _call(request)
			method = request.path
			method = method[1, method.size - 1] if method

			case method
				when "stat"
					Stat.inc(request['name']); '{"result":"ok"}'
				when "init"
					InitializeController.new(request).call
				when "levels/complete"
					LevelsController.new(request).call
				when "levels/manage"
					LevelsManageController.new(request).call
				when "rewards/move"
					RewardsMoveController.new(request).call
				when "users/show"
					UserInfoController.new(request).call
				when "posting/complete"
					PostingController.new(request).call
				when 'tutorial/inc'
					TutorialController.new(request).call
				when 'offer/add'
					OfferController.new(request).call
				when 'top/index'
					TopController.new(request).call
				when 'money/buy'
					BuyMoneySyncController.new(request).call
				when 'items/purchase'
					BuyUserItemController.new(request).call
				when 'items/use'
					UseItemController.new(request).call
				when 'customize/purchase'
					BuyUserCustomizeController.new(request).call
				when 'friends/update'
					UpdateFriendStorageController.new(request).call
				when 'friends/visit'
					FriendVisitRewardController.new(request).call
				when "levels.xml"
					LevelXmlGenerator.generate(request['release'])
					#LevelsAdminController.generate_xml_file(request['release'])
				when "config.txt"
					[200,{"Content-Type" => "text/plain; charset=UTF-8"},ConfigGenerator.generate(request['net'].to_i)]
				when /^lang\/.+/
					[200,{"Content-Type" => "text/plain; charset=UTF-8"},LangGenerator.generate(method.match(/^lang\/(.{2,10})/)[1])]
				# ADMIN AREA
				when /^admin/
					AdminController.new.call request
				when "crossdomain.xml"
					File.read("#{ROOT}/bin-debug/crossdomain.xml")
				when "openload"
					InitializeController.new(TestRequest.new({'json' => '{"user":{"net":1,"last_name":"","first_name":"Rabbit","uid":"1"}}', \
																									  'net' => '1', 'ping' => '1', 'uid' => '1', 'key' => 'embed' \
																											})).call
				when "images/manage"
					ImagesManageController.new(request).call	
				when "locales"
					content = ''
					Lang.all.each{|l| content << "#{l.key}=#{l.get(:ru)}\n#{l.key}=#{l.get(:en)}\n\n"}
					[200,{"Content-Type" => "text/plain; charset=UTF-8"},content]
				when /^payment\/\w+/
					NetApi.by_net(method.match(/^payment\/(?<net>\w+)/)[:net]).payment(request)
				else
					Hello.new.call request
			end

		end
	end
end

class TestRequest < HashWithIndifferentAccess
	def initialize(hash)
		@params = hash
		super(hash)
	end
	
	def params
		@params
	end
end
