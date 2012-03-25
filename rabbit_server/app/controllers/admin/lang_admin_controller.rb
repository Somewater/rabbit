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
		elsif(@request['create'])
			request_lang = @request['lang']
			lang = Lang[request_lang['key']]
			raise LogicError, "Key #{request_lang['key']} already exist" if lang
			lang = Lang.create(request_lang['key'], request_lang['value'], request_lang['locale'], @admin_user.user.login)
			lang.part = request_lang['part']
			lang.comment = request_lang['comment']
			# создаем пустые локали под заготовку
			LangLocale.find(:all, :select => 'locale', :group => 'locale').map(&:locale).each do |locale|
				if request_lang['locale'].to_s != locale.to_s
					lang.set(locale, nil, @admin_user.user.login)
				end
			end
			lang.save
			Lang.clear_cache()
		end

		if(@request['no_content'])
			'{"success":true}'
		else

			@part = @request['part'] && @request['part'].size > 0 ? @request['part'] : nil
			@parts = []
			@langs = []
			Lang.all_head().each do |key, lang|
				@langs << lang if @part == nil || lang.part == @part
				@parts << lang.part if lang.part && lang.part.size > 0 && !@parts.index(lang.part)
			end

			html({:title => (@part ? "Part - #{@part}" : nil), :javascript => true}) do
				template(File.read("#{TEMPLATE_ROOT}/admin/lang_admin_index.erb"))
			end
		end
	end

end
