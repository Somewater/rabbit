#!/usr/bin/env ruby
require_relative 'vk_notify_require'
require_relative 'vk_notify_worker'
type = ARGV[0].to_i

v = RabbitDaemon::VkNotifyWorker.new
puts "type=#{type}"
