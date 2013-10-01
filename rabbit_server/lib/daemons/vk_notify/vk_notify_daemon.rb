#!/usr/bin/env ruby
require_relative 'vk_notify_require'
require_relative 'vk_notify_worker'

Dir.mkdir "#{ROOT}/log/daemons" unless Dir.exist? "#{ROOT}/log/daemons"
logger = Logger.new("#{ROOT}/log/daemons/vk-notify-daemon.log", 10, 1024000)
worker = RabbitDaemon::VkNotifyWorker.new
worker.logger = logger
pidfile = "#{ROOT}/tmp/pids/rabbit-vk-notify.pid"

processor = RabbitDaemon::Processor.new(worker, logger, pidfile)
processor.process()
