ROOT = File.dirname( File.expand_path( __FILE__ ) )
$:.unshift("#{ROOT}/lib/tasks")
Dir["#{ROOT}/rabbit_server/lib/tasks/*.rake"].sort.each { |x| import x }

task :default => ["flash:compile"]

task :environment do
	require "#{ROOT}/rabbit_server/config/environment.rb"
end

##########################
#
#    	  FLASH
#
##########################
namespace :flash do
	MXMLC_COMMON_COMMANDLINE_ARGS="mxmlc -warnings=false -static-link-runtime-shared-libraries -default-background-color=#FFFFFF -default-frame-rate=30 -default-size 810 550 -target-player=10.0.0 -compiler.debug=true -use-network=true -define+=CONFIG::release,false  --keep-as3-metadata+=TypeHint,EditorData,Embed -benchmark=true -optimize=true -source-path+=src -source-path+=PBE/src -library-path+=src/assets/swc/library.swc -library-path+=lib/binding.swc -define+=CONFIG::debug,true"

	desc "Compile game [modulename]/all"
	task :compile, :filename do |task, args|
	  filename = args[:filename]
	  if(filename)
		compile_file filename
	  else
		compile_file "lang_ru"
		compile_file "RabbitGame"
		compile_file "RabbitApplication"
		compile_file "LocalRabbitLoader"
	  end
	  puts "=== Compilation success! ==="
	end

	desc "Compile Level Editor"
	task :compile_editor do
	  compile_editor_file "RabbitEditor"
	  puts "=== Compilation success! ==="
	end

	desc "Compile all stuff"
	task :compile_all do
	  compile_file "lang_ru"
	  compile_file "RabbitGame"
	  compile_file "RabbitApplication"
	  compile_file "LocalRabbitLoader"
	  compile_editor_file "RabbitEditor"
	  puts "=== Compilation success! ==="
	end

	desc "Encode all files"
	task :encode do
		RProtector.new.encode_files("#{ROOT}/logs")
	end

	def compile_file(filename)
		puts %x[#{MXMLC_COMMON_COMMANDLINE_ARGS} -output=bin-debug/#{filename}.swf src/#{filename}.as]
	end

	def compile_editor_file(filename)
	  puts %x[#{MXMLC_COMMON_COMMANDLINE_ARGS} -output=bin-debug/#{filename}.swf rabbit_editor/src/#{filename}.mxml]
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
	task :update do
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