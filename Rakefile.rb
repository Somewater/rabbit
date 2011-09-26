MXMLC_COMMON_COMMANDLINE_ARGS="mxmlc -warnings=false -static-link-runtime-shared-libraries -default-background-color=#FFFFFF -default-frame-rate=30 -default-size 810 550 -target-player=10.0.0 -compiler.debug=true -use-network=true -define+=CONFIG::release,false  --keep-as3-metadata+=TypeHint,EditorData,Embed -benchmark=true -optimize=true -source-path+=src -source-path+=PBE/src -library-path+=src/assets/swc/library.swc -library-path+=lib/binding.swc -define+=CONFIG::debug,true"

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

task :compile_editor do
  compile_editor_file "RabbitEditor"
  puts "=== Compilation success! ==="
end

task :compile_all do
  compile_file "lang_ru"
  compile_file "RabbitGame"
  compile_file "RabbitApplication"
  compile_file "LocalRabbitLoader"
  compile_editor_file "RabbitEditor"
  puts "=== Compilation success! ==="
end

def compile_file(filename)
	puts %x[#{MXMLC_COMMON_COMMANDLINE_ARGS} -output=bin-debug/#{filename}.swf src/#{filename}.as]
end

def compile_editor_file(filename)
  puts %x[#{MXMLC_COMMON_COMMANDLINE_ARGS} -output=bin-debug/#{filename}.swf rabbit_editor/src/#{filename}.mxml]
end
