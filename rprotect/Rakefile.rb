$debug = ENV['DEBUG'] ? ENV['DEBUG'].to_s == 'true' || ENV['DEBUG'].to_s == '1': false

task :environment do
	ROOT = File.expand_path('../',  __FILE__)
  WIN_OS = RUBY_PLATFORM.to_s =~ /(mingw|cygwin|mswin)/
end

desc "Compile library"
task :default => :environment do |debug|
	create_rprotect_wrapper()
	compile_library()
end

desc "Compile"
task :compile => :environment do
	create_rprotect_wrapper()

	puts 'compiled: SWFDecoderLoader'
	compile_file('Data')
	puts 'compiled: Data'
	compile_file('Test')
	puts 'compiled: Test'
end

desc "Encode"
task :encode => :environment do
	encode_file('Somefile')
end

desc "Test"
task :test => [:compile, :encode] do
	puts 'Start flash...'
	`/home/pav/bin/flashplayer #{ROOT}/Test.swf`
	puts 'Launch completed!'
end

def create_rprotect_wrapper
  untype_file("#{ROOT}/SWFDecoderLoader.as","#{ROOT}/SWFDecoderLoader_untyped.as")
	compile_file('SWFDecoderLoader_untyped')
	require 'fileutils'
	puts "You can obfuscate #{ROOT}/SWFDecoderLoader_untyped.swf [continue]"
	#g = STDIN.gets
	puts "Coping..."
	simple_encoding("#{ROOT}/SWFDecoderLoader_untyped.swf")
	FileUtils.cp "#{ROOT}/SWFDecoderLoader_untyped.swf", "#{ROOT}/com/somewater/net/SWFDecoderLoader.swf"
end

def compile_file file
	puts "Compiling #{file} ..."
	puts `mxmlc -default-background-color=#FFFFFF -default-frame-rate=24 -default-size 100 100 -target-player=10.0.0 -compiler.debug=#{$debug} -use-network=true -benchmark=true -optimize=true -output=#{file}.swf #{file}.as`
end

def compile_library()
	puts `compc -source-path "#{ROOT}" \
-include-classes "com.somewater.net.SWFDecoderWrapper" \
-optimize \
-compiler.debug=#{$debug} \
-target-player=10.0 \
-output "#{ROOT}/RProtector.swc"`
end

def encode_file file
	$: << ROOT
	require 'r_protector.rb'
	protector = RProtector.new
	compile_file('Data')
	protector.encode_file('Data.swf', 'Data.swf')
end

def untype_file(input_filepath, output_filepath)
	file = File.open(input_filepath, 'r')
	file = file.read
	file_untyped = ''
	file.each_line do |line|
	  line.gsub!(/\:\w+\)\:/, ':*):')
		file_untyped << line.gsub(/\:\w+(\s|;|,)/, ':*\1').gsub(/SWFDecoderLoader/,'SWFDecoderLoader_untyped')
	end
	File.open(output_filepath, 'w') {|f| f.write(file_untyped) }
end

def simple_encoding(swf_filepath)
	# todo: по простому заенкодить
end
