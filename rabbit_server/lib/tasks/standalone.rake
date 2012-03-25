namespace :standalone do
	desc 'Compile FGL'
	task :fgl => [:compile_config, :compile_lang] do
		Rake::Task['flash:configurate_compiler'].execute()
		Rake::Task['flash:compile'].execute()
		Rake::Task['flash:compile'].execute({:filename => 'FGLRabbitLoader'})
	end

	desc "Compile xml_pack from asflash.ru"
	task :compile_xml_pack => 'flash:configurate_compiler' do
		raise "TODO"
	end

	desc "Compile config.txt from asflash.ru"
	task :compile_config, [:net] => 'flash:configurate_compiler' do |task, args|
		begin
			net = args[:net].to_i
			config_txt = get_site_file('config.txt?net=' + net.to_s, "tmp_config.txt")
			config_swf_filepath = compile_tmp_file(tmp_config_file(), 'tmp_config_pack')
		ensure
			File.delete(config_txt) rescue nil
		end
	end

	desc "Compile language from asflash.ru"
	task :compile_lang, [:locale] => 'flash:configurate_compiler' do |task, args|
		begin
			require "yaml"
			locale = args[:locale] ? args[:locale] : (ENV['LOCALE'] ? ENV['LOCALE'].to_s : YAML.load(File.read("#{ROOT}/rabbit_server/config/public_config.yml"))['DEFAULT_LOCALE'].to_s)
			lang_txt = get_site_file("lang/#{locale}", "tmp_lang.txt")
			lang_swf_filepath = compile_tmp_file(tmp_lang_file(), 'tmp_lang_pack')
		ensure
			File.delete(lang_txt) rescue nil
		end
	end

	def get_site_file(urn, local_filename, base_path = nil)
		require "httparty"
		base_path = (ENV['BASE_PATH'] ? ENV['BASE_PATH'] : 'http://asflash.ru/') unless base_path
		response = HTTParty.get(base_path.to_s + urn.to_s)
		full_local_filename = "#{ROOT}/tmp/#{local_filename}"
		File.open(full_local_filename,'w') {|f| f.write(response) }
		full_local_filename
	end

	def compile_tmp_file(code, classname, output_filename = nil)
		begin
			output_filename = classname unless output_filename
			code_filepath = "#{ROOT}/tmp/#{classname}.as"
			File.open(code_filepath, 'w'){|f| f.write(code)}
			swf_filepath = "#{ROOT}/tmp/#{output_filename}.swf"
			puts %x[#{MXMLC_COMMON_COMMANDLINE_ARGS} -source-path+=tmp -output=#{swf_filepath} #{ROOT}/tmp/#{classname}.as]
		ensure
			File.delete(code_filepath) rescue nil
		end
		swf_filepath
	end
end

def tmp_config_file()
		<<-EOF
package
{
	import flash.display.Sprite;
	import flash.utils.getDefinitionByName;

	public class tmp_config_pack extends Sprite
	{
		[Embed("tmp_config.txt", mimeType="application/octet-stream")]
		private const ConfigPack:Class;


		public function tmp_config_pack()
		{
			var Config:Class = getDefinitionByName('com.somewater.rabbit.storage.Config') as Class;
			Config.loader.setData('Config', new ConfigPack());
		}
	}
}
EOF
end

def tmp_lang_file()
	<<-EOF
package
{
	import flash.display.Sprite;
	import flash.utils.getDefinitionByName;

	public class tmp_lang_pack extends Sprite
	{

		[Embed("tmp_lang.txt", mimeType="application/octet-stream")]
		private static const data : Class;

		public function tmp_lang_pack()
		{
			var Config:Class = getDefinitionByName('com.somewater.rabbit.storage.Config') as Class;
			Config.memory['lang_pack'] = new data();
		}
	}
}
	EOF
end