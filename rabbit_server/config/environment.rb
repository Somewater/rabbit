require "rack/timeout"
require "yaml"


# const ROOT must be initialize abowe!
SERVER_ROOT = "#{ROOT}/rabbit_server"
CONFIG_DIR = "#{SERVER_ROOT}/config"
DB_CONF = YAML.load(File.read("#{CONFIG_DIR}/database.yml"))
CONFIG  = YAML.load(File.read("#{CONFIG_DIR}/config.yml"))
RAILS_ENV = APP_ENV = ENV['RACK_ENV'] || "development"
DEVELOPMENT = true

##################################
#
#			E N V I R O N M E N T
#
##################################
require 'logger'
require 'active_record'
#require "active_record/connection_adapters/postgresql_adapter"
ActiveRecord::Base.configurations = DB_CONF
ActiveRecord::Base.establish_connection(
  DB_CONF[APP_ENV]
)


Dir["#{SERVER_ROOT}/app/*"].each{|a| $:.unshift(a)}
Dir["#{SERVER_ROOT}/app/{controllers,models}/*.rb"].sort.each { |x| require x }
Dir["#{SERVER_ROOT}/app/{controllers,models}/**/*.rb"].sort.each { |x| require x }

ActiveRecord::Base.logger = Application.logger
RAILS_ROOT = SERVER_ROOT
RAILS_DEFAULT_LOGGER = Application.logger

Application.logger.info { "Initialization complete [#{RUBY_VERSION}/#{RUBY_PLATFORM}] at #{Time.new}" }


