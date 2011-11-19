Encoding.default_external = Encoding::UTF_8

require "rack/timeout"
require "yaml"
require 'rexml/document'


# const ROOT must be initialize abowe!
SERVER_ROOT = "#{ROOT}/rabbit_server"
TEMPLATE_ROOT = "#{SERVER_ROOT}/app/views"
CONFIG_DIR = "#{SERVER_ROOT}/config"
PUBLIC_DIR = "#{ROOT}/bin-debug"
DB_CONF = YAML.load(File.read("#{CONFIG_DIR}/database.yml"))
CONFIG  = YAML.load(File.read("#{CONFIG_DIR}/config.yml"))
RAILS_ENV = APP_ENV = (ENV['RACK_ENV'] =~ /(production|development|test)/ ? ENV['RACK_ENV'] : "development")
DEVELOPMENT = (APP_ENV == 'development' ? true : false)
PRODUCTION = (APP_ENV == 'production' ? true : false)

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
  DB_CONF[APP_ENV == 'test' ? 'test' : 'development'] # development db forever
  #DB_CONF[APP_ENV]
)


Dir["#{SERVER_ROOT}/app/*"].each{|a| $:.unshift(a)}
Dir["#{SERVER_ROOT}/app/{controllers,models}/super/*.rb"].sort.each { |x| require x }
Dir["#{SERVER_ROOT}/app/{controllers,models}/*.rb"].sort.each { |x| require x }
Dir["#{SERVER_ROOT}/app/{controllers,models}/**/*.rb"].sort.each { |x| require x }

ActiveRecord::Base.logger = Application.logger
RAILS_ROOT = SERVER_ROOT
RAILS_DEFAULT_LOGGER = Application.logger

#######################################################
#
#	M A N A G E R S		I N I T I A L I Z A T I O N
#
#######################################################
RewardManager.instance

Application.logger.info { "Initialization complete [#{RUBY_VERSION}/#{RUBY_PLATFORM}] at #{Time.new}" }


