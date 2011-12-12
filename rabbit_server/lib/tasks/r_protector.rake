require "digest/md5"

class RProtector

	ENCODED_FILE_POSTFIX = '_encoded.swf'

  HIGH = (Math.sin(0.216434) * 10**10).to_i # 2147481926, максимум 2**31-1 = 2147483647
  LOW = 16126 # в оригинале 16147 (хз почему)

	def initialize(seed = nil)
		@seed = seed ? seed : 8
	end

	def encode_files path, mask = '*.swf'
		path << '/' unless path[-1] == '/'
		Dir["#{path}#{mask}"].each do |filepath|
			filename = File.basename(filepath)
			break if filename[-ENCODED_FILE_POSTFIX.length..-1] == ENCODED_FILE_POSTFIX
			filename[-4..-1] = "" if filename[-4..-1].downcase == '.swf'
			encoded_filepath = "#{File.dirname(filepath)}/#{filename}#{ENCODED_FILE_POSTFIX}"
			encode_file(filepath, encoded_filepath)
		end
	end

	def encode_file(input_filepath, output_filepath)
		raise RProtectorError, "File #{input_filepath} not exist" unless File.exist?(input_filepath)
		output_bin_filepath = "#{output_filepath}.bin"
		as_classname = "EncodedData_#{rand(10000)}"
		output_as_filepath = "#{File.dirname(output_filepath)}/#{as_classname}.as"
		File.open(input_filepath, 'rb') do |input_file|
			File.open(output_bin_filepath, 'wb') do |output_bin_file|
				input_file.each_byte do |byte|
					#output_bin_file.write([encode_byte(byte)].pack('C'))
					output_bin_file.putc(encode_byte(byte))
				end
			end
		end
		File.open(output_as_filepath, 'w') {|as| as.write(actionscript_file(as_classname, output_bin_filepath))}
		`mxmlc -output #{output_filepath} #{output_as_filepath}`
	ensure
		File.delete(output_as_filepath, output_bin_filepath) rescue nil
	end

	def encode_byte(input)
		input ^ random.to_i
	end

	def actionscript_file(classname, bin_filepath)
		content = <<-EOF
package
{
	import flash.display.Sprite;

	public class #{classname} extends Sprite
	{
		[Embed(source="#{bin_filepath}", mimeType="application/octet-stream")]
		public var scalar:Class;


		public function #{classname}()
		{
			graphics.beginFill(0x006600);
			graphics.drawRect(5,5,5,5);
		}
	}
}
	EOF
		content
	end

	def random
		multiply = @seed.to_f * LOW;
		@seed =multiply % HIGH;
		(@seed.to_f / HIGH) * 256;
	end
end

=begin
	Использование
	RProtectorVersionizer.instance('/home/user/project/tmp/version_file.txt')
	RProtectorVersionizer.instance.process('/home/user/some.swf') # закодировать, если еще не был закодирован
=end
class RProtectorVersionizer

	@@instance = nil

	def self.instance(arg = nil)
		unless @@instance
			@@instance = RProtectorVersionizer.new(arg)
		end
		@@instance
	end

	def initialize(path_to_version_file)
		@path_to_version_file = path_to_version_file
		@by_filepath = {}

		if(File.exists?(path_to_version_file))
			File.open(path_to_version_file) do |file|
				file.each_line do |line|
					hash, filepath = line.split
					@by_filepath[filepath] = hash
				end
			end
		end
	end

	def protected?(filepath)
		if @by_filepath[filepath]
			@by_filepath[filepath] == filepath_to_hash(filepath)
		else
			false
		end
	end

	def encode(filepath)
		unless protected?(filepath)
			RProtector.new.encode_file(filepath, filepath)
			hash = @by_filepath[filepath] = filepath_to_hash(filepath)
			save_version_file
			return hash
		end
		false
	end

	private
	def filepath_to_hash (filepath)
		Digest::MD5.hexdigest(File.read(filepath))
	end

	def save_version_file
		File.open(@path_to_version_file, 'w') do |file|
			@by_filepath.each do |filepath, hash|
				file.puts("#{hash} #{filepath}")
			end
		end
	end
end

class RProtectorError < StandardError

end