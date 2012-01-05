ROOT = File.dirname( File.expand_path( __FILE__ ) )

require "#{ROOT}/rabbit_server/config/environment.rb"

Application.logger.info { "Initialization complete [#{RUBY_VERSION}/#{RUBY_PLATFORM}/#{APP_ENV}] at #{Application.time}" }

Rack::Timeout.timeout = (DEVELOPMENT ? 600 : 10)
if PRODUCTION
	run Rack::Timeout.new(Application)
else
	run Rack::URLMap.new( {
	  "/files" => Rack::Directory.new( "bin-debug" ),
	  "/" => Rack::Timeout.new(Rack::Runtime.new(Application))
	} )
end
