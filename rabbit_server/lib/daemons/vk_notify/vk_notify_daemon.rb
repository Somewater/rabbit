#!/usr/bin/env ruby
ROOT = File.expand_path File.join(File.dirname( File.expand_path( __FILE__ )), "..", "..", "..", "..")
require "#{ROOT}/rabbit_server/config/environment.rb"
require_relative "../rabbit_daemon"
require_relative 'vk_notify_worker'

logger = Logger.new("#{ROOT/log/daemons/vk-notify-daemon.log}", 10, 1024000)
worker = RabbitDaemon::VkNotifyWorker.new
worker.logger = logger

processor = RabbitDaemon::Processor.new(worker, logger)
processor.process()
