task :environment do
  ROOT = File.expand_path('../',  __FILE__)
  $:.push("#{ROOT}/../rprotect")
  require 'r_protector'
end

desc "Compile SocialFree.swc"
task :social => :environment do
	library('Social', 'SocialFree')	
end

desc "Compile encoded Social.swc"
task :default => :social do
  begin
		classes = nil
		File.open("#{ROOT}/Social.as") do |file| 
			file.each_line do |line|
				if(line.index(/\[.+\]/))
						classes = line.scan(/(?:\[|,|,\s+)(\w+)/).map{|m| m.first.to_s}
					break
				end
			end
		end
	
		files = []
	
		classes.each do |cl|
			files << compile_arrow(cl)
		end
	
		files.each{|file|
			factory = file[:factory_classname] = "#{file[:classname]}Factory"
			as_factory = "#{ROOT}/#{factory}.as"
			File.open(as_factory, 'w') { |as| 
				as.write(actionscript_file_arrow_factory(file[:classname], file[:swf]))
				file[:factory] = as_factory
				file[:factory_class] = factory
			}
		}
	
		classes = files.map{|file| file[:factory_class] }.join(' ')
		classes << ' com.somewater.social.SocialUser'
		
		puts "Compile Social.swc. Classes: #{classes}"
		library(classes, 'Social')
	ensure
		if files
			deleting = []
			files.each do |file|
				deleting << file[:swf]
				deleting << file[:as]
				deleting << file[:factory]
			end
			File.delete(* deleting)
		end
	end
end

def compile_arrow(classname)
  classname_ext = "#{classname}_#{rand(2000000000).to_s}"
	File.open("#{ROOT}/#{classname_ext}.as", 'w') {|as| as.write(actionscript_file(classname_ext, classname))}
	compile(classname_ext)
	protector = RProtector.new
	protector.encode_file("#{ROOT}/#{classname_ext}.swf","#{ROOT}/#{classname_ext}.swf")
	{:as => "#{ROOT}/#{classname_ext}.as", :swf => "#{ROOT}/#{classname_ext}.swf", :classname => classname}
end

def library(classname, output, debug = true)
	puts `compc -source-path "#{ROOT}" \
	-include-classes #{classname} \
	-optimize \
	-target-player=10.0 \
	-compiler.debug=#{debug} \
	-output "#{ROOT}/#{output}.swc"`
end

def compile(file, debug = true)
	puts `mxmlc \
	-target-player=10.0 \
	-compiler.debug=#{debug} \
	-library-path+=SocialFree.swc \
	-use-network=true \
	-optimize=true \
	-output=#{file}.swf \
	#{file}.as`
end

def actionscript_file(classname, superclassname)
	content = <<-EOF
package
{
	import com.somewater.arrow.*  
	public class #{classname} extends #{superclassname}
	{
		public function #{classname}()
		{

		}
	}
}
	EOF
	content
end

def actionscript_file_arrow_factory(classname, filename)
	content = <<-EOF
package
{
	import flash.utils.ByteArray;
	
	public class #{classname}Factory
	{
		
		[Embed(source=\"#{filename}\", mimeType=\"application/octet-stream\")]
		private static const _arrow:Class;
		
		public static function get create():ByteArray
		{
			return new _arrow();
		}
	}
}
	EOF
	content
end
