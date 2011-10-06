ROOT = File.dirname( File.expand_path( __FILE__ ) )

require "#{ROOT}/rabbit_server/config/environment.rb"

Rack::Timeout.timeout = (DEVELOPMENT ? 60 : 10)
run Rack::URLMap.new( {
  "/files" => Rack::Directory.new( "bin-debug" ),
  "/" => Rack::Timeout.new(Rack::Runtime.new(Application))
} )
