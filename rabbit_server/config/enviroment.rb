require "rack/timeout"

DB_CONF = YAML.load(File.read("#{CONFIG_DIR}/database.yml"))
CONFIG  = YAML.load(File.read("#{CONFIG_DIR}/config.yml"))

##################################
#
#			E N V I R O N M E N T
#
##################################
require 'logger'
require 'active_record'
#require "active_record/connection_adapters/postgresql_adapter"

ActiveRecord::Base.establish_connection(
  DB_CONF['production']
)


Dir["#{SERVER_ROOT}/app/*"].each{|a| $:.unshift(a)}
Dir["#{SERVER_ROOT}/app/{controllers,models}/*.rb"].sort.each { |x| require x }
Dir["#{SERVER_ROOT}/app/{controllers,models}/**/*.rb"].sort.each { |x| require x }

ActiveRecord::Base.logger = Application.logger
RAILS_ROOT = SERVER_ROOT
RAILS_DEFAULT_LOGGER = Application.logger

Application.logger.info { "Initialization complete [#{RUBY_VERSION}/#{RUBY_PLATFORM}]" }


