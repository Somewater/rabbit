module LangGenerator
	def self.generate(locale)
		response = "# RABBIT LANG FILE (locale='#{locale}')\n"
		Lang.all_head.each do |key, lang|
			response << key << '=' << lang.get(locale).to_s << "\n"
		end
		response
	end
end