# encoding: utf-8

require 'redis'
require 'json'

module RabbitDaemon
	module QueueSubscriber
		def initialize_queue(name_space)
			@name_space = name_space
			@redis = Redis.new
		end

		def push_to_queue(value)
			@redis.rpush(@name_space, value ? JSON.fast_generate(value) : 'nil')
		end

		def shift_from_queue()
			value = @redis.lpop(@name_space)
			(value.nil? || value == 'nil' ? nil : JSON.parse(value)) rescue nil
		end

		def queue_size()
			@redis.llen(@name_space).to_i
		end
	end
end
