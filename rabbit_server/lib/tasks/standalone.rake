namespace :standalone do
	desc 'Compile FGL'
	task :fgl do
		ENV['SITELOCK'] = "flashgamelicense.com"
		ENV['LOCALE'] = 'en'
		ENV['USE_MXMLC'] = 'true'
		ENV['LOADERNAME'] = 'FGLRabbitLoader'
		Rake::Task['flash:configurate_compiler'].execute()
		Rake::Task['standalone:compile_config'].execute()
		Rake::Task['standalone:compile_lang'].execute()
		Rake::Task['flash:compile'].execute()
		Rake::Task['flash:encode'].execute()
		Rake::Task['flash:compile'].execute({:filename => 'FGLRabbitLoader'})
		puts "******************************\n\tWARNING LOCALE = #{ENV['LOCALE']}\n******************************" if ENV['LOCALE'] != 'en'
		puts "******************************\n\tWARNING SITELOCK NOT ASSIGNED\n******************************" unless ENV['SITELOCK']
  end

	desc 'Compile Mochi'
	task :mochi do
		ENV['SITELOCK'] = "*"
		ENV['LOCALE'] = 'en'
		ENV['USE_MXMLC'] = 'true'
		ENV['LOADERNAME'] = 'MochiRabbitLoader'
		Rake::Task['flash:configurate_compiler'].execute()
		Rake::Task['standalone:compile_config'].execute()
		Rake::Task['standalone:compile_lang'].execute()
		Rake::Task['flash:compile'].execute()
		Rake::Task['flash:encode'].execute()
		Rake::Task['flash:compile'].execute({:filename => 'MochiRabbitLoader'})
		puts "******************************\n\tWARNING LOCALE = #{ENV['LOCALE']}\n******************************" if ENV['LOCALE'] != 'en'
		puts "******************************\n\tWARNING SITELOCK NOT ASSIGNED\n******************************" unless ENV['SITELOCK']
	end

	desc 'Compile AIR'
	task :airswf, [:preloader_only] do |task, args|
		ENV['SITELOCK'] = "*"
		ENV['LOCALE'] = 'en'
		$air = true
		#ENV['USE_MXMLC'] = 'true'
		ENV['LOADERNAME'] = 'AIRSWFRabbitLoader'
		Rake::Task['flash:configurate_compiler'].execute()
		unless args[:preloader_only]
			Rake::Task['standalone:compile_config'].execute()
			Rake::Task['standalone:compile_lang'].execute()
			Rake::Task['flash:compile'].execute()
			Rake::Task['flash:encode'].execute()
		end
		Rake::Task['flash:compile'].execute({:filename => 'AIRSWFRabbitLoader'})
		require 'fileutils'
		FileUtils
		FileUtils.mv "#{ROOT}/bin-debug/AIRSWFRabbitLoader.swf", "#{ROOT}/air/output/AIRSWFRabbitLoader.swf"
		puts "******************************\n\tWARNING LOCALE = #{ENV['LOCALE']}\n******************************" if ENV['LOCALE'] != 'en'
		#puts "******************************\n\tWARNING SITELOCK NOT ASSIGNED\n******************************" unless ENV['SITELOCK']
	end

	desc 'Compile FLASH GAMM'
	task :gamm do
		ENV['SITELOCK'] = "flashgamm.com"
		ENV['LOCALE'] = 'en'
		ENV['USE_MXMLC'] = 'true'
		ENV['LOADERNAME'] = 'GAMMRabbitLoader'
		Rake::Task['flash:configurate_compiler'].execute()
		Rake::Task['standalone:compile_config'].execute()
		Rake::Task['standalone:compile_lang'].execute()
		$debug = false
		Rake::Task['flash:compile'].execute()
		Rake::Task['flash:encode'].execute()
		Rake::Task['flash:compile'].execute({:filename => 'GAMMRabbitLoader'})
		puts "******************************\n\tWARNING LOCALE = #{ENV['LOCALE']}\n******************************" if ENV['LOCALE'] != 'en'
		puts "******************************\n\tWARNING SITELOCK NOT ASSIGNED\n******************************" unless ENV['SITELOCK']
	end

	desc 'Compile to rabbit.atlantor.ru'
	task :atlantor do
		ENV['SITELOCK'] = "atlantor.ru"
		ENV['LOCALE'] = 'en'
		ENV['USE_MXMLC'] = 'true'
		ENV['LOADERNAME'] = 'GAMMRabbitLoader'
		Rake::Task['flash:configurate_compiler'].execute()
		Rake::Task['standalone:compile_config'].execute()
		Rake::Task['standalone:compile_lang'].execute()
		$debug = false
		Rake::Task['flash:compile'].execute()
		Rake::Task['flash:encode'].execute()
		Rake::Task['flash:compile'].execute({:filename => 'GAMMRabbitLoader'})
		puts "******************************\n\tWARNING LOCALE = #{ENV['LOCALE']}\n******************************" if ENV['LOCALE'] != 'en'
		puts "******************************\n\tWARNING SITELOCK NOT ASSIGNED\n******************************" unless ENV['SITELOCK']
	end

	desc "Compile xml_pack from atlantor.ru"
	task :compile_xml_pack => 'flash:configurate_compiler' do
    begin
      levels_file = get_site_file('levels.xml', "tmp_levels.xml")
      text_without_nn = File.open(levels_file).read.gsub(/(\r|\n)+/, "\n")
      File.open("#{ROOT}/bin-debug/Levels.xml", 'w'){|f| f.write(text_without_nn) }
      Rake::Task['flash:compile'].execute({:filename => 'xml_pack'})
    ensure
      #File.delete(levels_file) rescue nil
    end
	end

	desc "Compile config.txt from atlantor.ru"
	task :compile_config, [:net, :production_too] => 'flash:configurate_compiler' do |task, args|
		begin
			net = args[:net].to_i
			config_txt = get_site_file('config.txt?net=' + net.to_s, "tmp_config.txt")
			config_swf_filepath = compile_tmp_file(tmp_config_file(), 'tmp_config_pack')
			FileUtils.cp(config_swf_filepath, "#{ROOT}/bin-debug/config_pack.swf") if args[:production_too]
		ensure
			#File.delete(config_txt) rescue nil
		end
	end

	desc "Compile language from atlantor.ru"
	task :compile_lang, [:locale, :production_too] => 'flash:configurate_compiler' do |task, args|
		begin
			require "yaml"
			locale = args[:locale] ? args[:locale] : (ENV['LOCALE'] ? ENV['LOCALE'].to_s : YAML.load(File.read("#{ROOT}/rabbit_server/config/public_config.yml"))['DEFAULT_LOCALE'].to_s)
			lang_txt = get_site_file("lang/#{locale}", "tmp_lang.txt")
			lang_swf_filepath = compile_tmp_file(tmp_lang_file(), 'tmp_lang_pack')
			FileUtils.cp(lang_swf_filepath, "#{ROOT}/bin-debug/lang_pack.swf") if args[:production_too]
		ensure
			#File.delete(lang_txt) rescue nil
		end
	end

	def get_site_file(urn, local_filename, base_path = nil)
		require "httparty"
		base_path = (ENV['BASE_PATH'] ? ENV['BASE_PATH'] : 'http://rabbit.atlantor.ru/') unless base_path
		response = HTTParty.get(base_path.to_s + urn.to_s).body
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
