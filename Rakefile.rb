# encoding: utf-8

# Используемые переменные среды:
# LOCALE - локаль компиляции языкового конфига
# BASE_PATH - адрес сервера, с которого берется конфиг
# DEBUG - компиляция в дебаг-може
# SITELOCK разрешенный для использования игры сайт, формата "asflash.ru"
# USE_MXMLC форсированно применять mxmlc, а не fcshctl-mxmlc

ROOT = File.dirname( File.expand_path( __FILE__ ) )
WIN_OS = RUBY_PLATFORM['mswin'] || RUBY_PLATFORM['mingw'] || RUBY_PLATFORM['cygwin']
$:.unshift("#{ROOT}/lib/tasks")
Dir["#{ROOT}/rabbit_server/lib/tasks/*.rake"].sort.each { |x| import x }
require 'rake'

$debug = ENV['DEBUG'] ? ENV['DEBUG'].to_s == 'true' || ENV['DEBUG'].to_s == '1': false

task :default => ["flash:compile"]

task :environment do
	require "#{ROOT}/rabbit_server/config/environment.rb"
end


task :vk_environment => :environment do
	require "vkontakte"
	Vkontakte.setup do |config|
	  config.app_id = "2732721 "
	  config.app_secret = "kJ0AVDo3he9GhGlhkmha"
	  config.format = :json
	  config.debug = false
	  config.logger = File.open("#{ROOT}/logs/vkontakte.log", "a") if DEVELOPMENT
	end
end

##########################
#
#    	  FLASH
#
##########################
namespace :flash do

	desc 'Configurate compiler keys'
	task :configurate_compiler do
	MXMLC_COMMON_COMMANDLINE_ARGS="#{ENV['USE_MXMLC'] || `which fcshctl-mxmlc`.size == 0 ? 'mxmlc' : 'fcshctl-mxmlc'} \
-warnings=false \
-static-link-runtime-shared-libraries \
-default-background-color=#FFFFFF \
-default-frame-rate=30 \
-default-size 810 550 \
-target-player=10.0.0 \
-compiler.debug=#{$debug ? 'true' : 'false'} \
-use-network=true \
-define+=CONFIG::debug,#{$debug ? 'true' : 'false'} \
-define+=CONFIG::sitelock,\"'#{ENV['SITELOCK'] ? Digest::MD5.hexdigest(ENV['SITELOCK'].to_s) : 'flash.display::Sprite'}'\" \
-define+=CONFIG::loadername,\"'#{ENV['LOADERNAME'] ? ENV['LOADERNAME'] : 'FGLRabbitLoader'}'\" \
--keep-as3-metadata+=TypeHint,EditorData,Embed \
-benchmark=true \
-optimize=true \
-source-path+=src \
-source-path+=PBE/src \
-source-path+=soc \
-library-path+=src/assets/swc/library.swc \
-library-path+=lib \
-library-path+=rprotect/RProtector.swc \
-library-path+=soc/Social.swc"

	COMPC_COMMON_COMMANDLINE_ARGS="compc \
-target-player=10.0 \
-compiler.debug=true \
-optimize"
	end

	desc "Compile game [modulename]/all"
	task :compile, [:filename] => :configurate_compiler do |task, args|
	  filename = args[:filename]
	  if(filename)
		compile_file filename
	  else
		compile_file "RabbitGame"
		compile_file "RabbitApplication"
		compile_file "EmbedRabbitLoader"
		compile_file "xml_pack"
	  end
	  puts "=== Compilation success! ==="
	end

	desc "Compile Level Editor"
	task :compile_editor => :configurate_compiler do
	  compile_editor_file "RabbitEditor"
	  puts "=== Compilation success! ==="
	end

	desc "Compile all stuff"
	task :compile_all => [:compile, :compile_editor] do
	  puts "=== Compilation success! ==="
	end

	desc "Encode all files"
	task :encode => :configurate_compiler do
		RProtectorVersionizer.instance("#{ROOT}/tmp/rprotector_versions.txt")
		bin_folder = "#{ROOT}/bin-debug"
		RProtectorVersionizer.instance.encode("#{bin_folder}/RabbitApplication.swf")
		RProtectorVersionizer.instance.encode("#{bin_folder}/RabbitGame.swf")
		RProtectorVersionizer.instance.encode("#{bin_folder}/assets/interface.swf")
		RProtectorVersionizer.instance.encode("#{bin_folder}/assets/rabbit_asset.swf")
	end

	def compile_file(filename)
		puts %x[#{MXMLC_COMMON_COMMANDLINE_ARGS} -output=bin-debug/#{filename}.swf src/#{filename}.as]
	end

	def compile_editor_file(filename)
	  puts %x[#{MXMLC_COMMON_COMMANDLINE_ARGS} -output=bin-debug/#{filename}.swf rabbit_editor/src/#{filename}.mxml]
	end
end

desc "Fcsh tasks"
namespace :fcsh do
	desc "Stop fcsh background process"
	task :stop do
		File.delete("#{ROOT}/screenlog.0") rescue nil
		File.delete("/tmp/fcshctl_screen_log") rescue nil
		10.times{puts %x[killall -r fcsh]}
	end
end


desc "Server tasks"
namespace :srv do
	desc "Initialize server"
	task :initialize do
		FileUtils.mkdir("#{ROOT}/logs")
		["production.log","development.log","test.log"].each {|file| FileUtils.touch("#{ROOT}/logs/#{file}")}
		FileUtils.mkdir("#{ROOT}/tmp")
		["always_restart.txt","restart.txt"].each {|file| FileUtils.touch("#{ROOT}/tmp/#{file}")}
	end

	desc "Update source and restart server"
	task :update => 'flash:encode' do
		`git push`
		sleep(5) #KLUDGE
		ssh = Execution.new("ssh root@asflash.ru")
		puts ssh.cmd "cd rabbit"
		puts ssh.cmd "git pull", 10
		puts ssh.cmd "\n"
		puts ssh.cmd "qlementina27\n"
		sleep(5)
		puts ssh.cmd "touch tmp/restart.txt"
		sleep(1)
		puts ssh.cmd "exit" rescue "== EXITED =="
		scp = Execution.new("scp -v #{ROOT}/bin-debug/*.swf root@asflash.ru:/srv/www/rabbit.asflash.ru/bin-debug/", /debug1\: Exit status 0/);
		scp = Execution.new("scp -v #{ROOT}/bin-debug/assets/*.swf root@asflash.ru:/srv/www/rabbit.asflash.ru/bin-debug/assets/", /debug1\: Exit status 0/);
	end

	desc "Upload swfs"
	task :upload => 'flash:encode' do
		if WIN_OS
			WIN_OS_ROOT = '/c/Work/Gamedev/RabbitGame'
			%x[scp #{WIN_OS_ROOT}/bin-debug/*.swf root@asflash.ru:/srv/www/rabbit.asflash.ru/bin-debug/]
			%x[scp #{WIN_OS_ROOT}/bin-debug/assets/*.swf root@asflash.ru:/srv/www/rabbit.asflash.ru/bin-debug/assets/]
		else
			scp = Execution.new("scp -v #{ROOT}/bin-debug/*.swf root@asflash.ru:/srv/www/rabbit.asflash.ru/bin-debug/", /debug1\: Exit status 0/);
			scp = Execution.new("scp -v #{ROOT}/bin-debug/assets/*.swf root@asflash.ru:/srv/www/rabbit.asflash.ru/bin-debug/assets/", /debug1\: Exit status 0/);
		end
	end
	
	desc "Start send notify queue from BD"
	task :notify => :vk_environment do
		# select next notify
		notify = Notify.find(:all, :conditions => "enabled=TRUE").first
		break unless notify

		app = Vkontakte::App::Secure.new

		logger = Logger.new(File.join(ROOT, %W{ logs vkontakte.log}))
		logger.level = Logger::DEBUG
		logger.formatter = Logger::Formatter.new
		
		puts "=== Process started at #{Time.new} ==="
		100.times do |step|
			break unless notify.enabled
		
			# select users
			user_uids = User.find(:all, :select => 'uid', :limit => 100, :offset => notify.position, \
			 			:conditions => 'net=2', :order => 'uid').map(&:uid)
		
			begin
				response = nil
				response = app.secure.sendNotification({:uids => user_uids.join(','), :message => notify.message})
				notify.position += 100
				logger.warn("Success notify\n#{user_uids} => #{response ? response.body : nil}");
			rescue Vkontakte::App::VkException
				logger.error("Error when notify\n#{user_uids} => #{$!}")
			rescue
				logger.fatal("Fatal when notify\n#{user_uids} => #{$!}")
			end

			# save notified users index in DB
			notify.enabled = user_uids && user_uids.size > 0
			notify.save
			puts "STEP #{step} completed at #{Time.new}, position #{notify.position}"
			sleep(1)
		end
		puts "=== Notify #{notify.enabled ? 'completed' : 'paused'} at #{Time.new} ==="
	end

	desc "Server fixes"
	task :fix, [:name,:arg1,:arg2] => :environment do |task, args|
		case args[:name].to_sym
			when :offers_db_fix
				OffersDbStringErrorFix::execute()
			when :prize
				# arg1 = customize type,  arg = customize id  (rake srv:fix[prize,door,111])
				OffersGivePrize::execute(args[:arg1].to_s, args[:arg2].to_i)
			else
				puts "Undefined fix name"
		end
	end

	desc "Recalculate TOP"
	task :top_cache => :environment do
		TopManager.instance.write_files()
	end

	desc "Cron hourly job"
	task :hourly => :environment do
		TopManager.instance.write_files()
	end
end


desc "Protect"
namespace :protect do

	desc "Compile Test"
	task :compile do
		#`stripper -i #{ROOT}/bin-debug/_RProtector.swf -o #{ROOT}/bin-debug/_RProtector.swf`
		`tdsi -i #{ROOT}/bin-debug/_RProtector.swf -o #{ROOT}/bin-debug/RProtector.swf`
		`stripper -i #{ROOT}/bin-debug/RProtector.swf -o #{ROOT}/bin-debug/RProtector.swf`
	end

	desc "Dump test"
	task :dump => [:compile] do
		#`dump -i #{ROOT}/bin-debug/_RProtector.swf -o #{ROOT}/tmp/dump -abc`
		`dump -i #{ROOT}/bin-debug/RProtector.swf -o #{ROOT}/tmp/dump -abc`
	end

end

desc "Gamedesign"
namespace :gamedesign do
	desc "Level statisic [all_levels, [all_versions, [condition]]]"
	task :level_stat, [:all_levels, :all_versions, :conditions] => :environment do |task, args|
		all_levels = (args[:all_levels] || '0').to_i > 0
		all_versions = (args[:all_versions] || '1').to_i > 0
		Gamedesign::level_stat(all_levels, all_versions, args[:conditions]);
	end

	desc "Clear statistic about test levels"
	task :clear_test_stat, [:test_level]  => :environment do |task, args|
		test_level = args[:test_level].to_i
		raise "Wrong level #{test_level}" if test_level.to_i <= 1
		Gamedesign::clear_test_levels_stat(test_level)
	end
end

desc "Mail.ru"
namespace :mailru do
	desc "Create archive for hosting"
	task :zip => ['flash:encode'] do
		require 'fileutils'
		puts 'Encoding completed'
		files = ['lang_pack.swf','RabbitApplication.swf','RabbitGame.swf','xml_pack.swf',\
			'assets/fonts_ru.swf','assets/interface.swf','assets/music_game.swf',\
			'assets/music_menu.swf','assets/rabbit_asset.swf','assets/rabbit_images.swf',\
			'assets/rabbit_reward.swf','assets/rabbit_sound.swf']
		files.each{|file|
			FileUtils.cp("#{ROOT}/bin-debug/#{file}", "#{ROOT}/tmp/mailrupack/#{file.sub(/\w+\//, '')}")
		}
		File.delete("#{ROOT}/tmp/mailrupack.zip") rescue nil
		puts %x[zip -j #{ROOT}/tmp/mailrupack.zip #{ROOT}/tmp/mailrupack/*]
	end

	desc "Test mailru notify"
	task :notify, [:text] => :environment do |task, args|
		uids = User.find(:all, :conditions => "net=3").map{|u| u.uid}
		(0..uids.size).step(100) do |iterator|
			p "ITERATOR #{iterator}"
			NetApi.by_net(3).notify(uids.slice(iterator, 100), args[:text])
		end
	end
end
