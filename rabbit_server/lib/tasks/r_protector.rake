class RProtector

	ENCODED_FILE_POSTFIX = '_encoded.swf'

	def initialize
		@seed = 7
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
		system("mxmlc -output #{output_filepath} #{output_as_filepath}")
		File.delete(output_as_filepath, output_bin_filepath)
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
		[Embed(source="#{filename}", mimeType="application/octet-stream")]
		public var scalar:Class;


		public function #{classname}()
		{

		}
	}
}
	EOF
		content
	end

	def random
		multiply = @seed.to_f * 16147;
		@seed =multiply % 2147483647;
		(@seed.to_f / 2147483647) * 256;
	end
end
