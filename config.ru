APP_ENV = ENV['RACK_ENV']
DEVELOPMENT = true
ROOT = File.dirname( File.expand_path( __FILE__ ) )
SERVER_ROOT = "#{ROOT}/rabbit_server"
CONFIG_DIR = "#{SERVER_ROOT}/config"

require "#{CONFIG_DIR}/enviroment.rb"

Rack::Timeout.timeout = 10
run Rack::URLMap.new( {
  "/files" => Rack::Directory.new( "bin-debug" ),
  "/" => Rack::Timeout.new(Rack::Runtime.new(Application))
} )
