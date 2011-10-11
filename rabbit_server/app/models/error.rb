class Error < ActiveRecord::Base
	establish_connection(DB_CONF['stat'])
end