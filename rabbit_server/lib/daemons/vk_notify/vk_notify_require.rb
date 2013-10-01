ROOT = File.expand_path File.join(File.dirname( File.expand_path( __FILE__ )), "..", "..", "..", "..")
require "#{ROOT}/rabbit_server/config/environment.rb"
require_relative "../rabbit_daemon"
require_relative 'vk_notify_worker'
