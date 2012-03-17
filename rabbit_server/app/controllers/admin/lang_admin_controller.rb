class LangAdminController < AdminController::Base
	LANG_PATH = '/admin/lang'
	
	def check_permissions()
		raise AuthError, "Illegal operation" unless @admin_user.can?(AdminUser::PERMISSION_LANGS)
	end

	def self_binding
		binding
	end

	def call
		if(@request['edit'])
			edit_id = @request['edit'].to_i
			if(@request['type'] == 'lang')
				lang = Lang.find(edit_id)
				lang.update_attributes(@request['lang'])
				lang.save
			elsif(@request['type'] == 'locale')
				lang_locale = LangLocale.find(edit_id)
				@request['locale']['value'].gsub!(/\n/,'\n')
				lang_locale.update_attributes(@request['locale'])
				lang_locale.author = @admin_user.user.login
				lang_locale.save
			else
				raise UnimplementedError, "Undefined type"
			end
			Lang.clear_cache()
		end

		@part = @request['part'] && @request['part'].size > 0 ? @request['part'] : nil
		@parts = []
		@langs = []
		Lang.all_head().each do |key, lang|
			@langs << lang if @part == nil || lang.part == @part
			@parts << lang.part if lang.part && lang.part.size > 0 && !@parts.index(lang.part)
		end

		if(@request['no_content'])
			'{"success":true}'
		else
			html({:title => (@part ? "Part - #{@part}" : nil), :javascript => true}) do
				template(File.read("#{TEMPLATE_ROOT}/admin/lang_admin_index.erb"))
			end
		end
	end

end
