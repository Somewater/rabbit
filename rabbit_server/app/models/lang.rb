# класс для логгирования денежных операций
class Lang < ActiveRecord::Base

	@@all_head = nil

	def set(locale, text, author = nil)
		locale = self.class.to_locale(locale)
		lang_locale = get_locale(locale)
		unless(lang_locale)
			lang_locale = LangLocale.new
			lang_locale.key = self.key
			lang_locale.locale = locale
		end
		lang_locale.author = author if author
		lang_locale.value = text
		lang_locale.save
		@locales = nil
		lang_locale
	end

	def get(locale)
		lang_locale = get_locale(locale)
		lang_locale ? lang_locale.value : nil
	end

	def get_locale(locale)
		locale = self.class.to_locale(locale)
		unless @locales
			@locales = {}
			LangLocale.where(:key => self.key).each do |l|
				@locales[l.locale] = l
			end
		end
		@locales[locale]
	end

	# все локали, соответствующие данному ключу, в виде хэша
	def locales
		unless @locales
			@locales = {}
			LangLocale.where(:key => self.key).each do |lang_locale|
				@locales[lang_locale.locale] = lang_locale
			end
		end
		@locales
	end

	# получить Lang, с преезгрузкой БД
	def self.[](key)
		self.find(:first, :conditions => {:key => key.to_s})
	end

	# получить значение языковой константы, воспользовавшись кэшом
	def self.t(key, params = nil, locale = nil)
		l = self.all_head()[key.to_s]
		l ? l.get(locale) : nil
	end

	def self.create(key, value, locale, author = nil)
		lang = self[key]
		unless lang
			lang = Lang.new
			lang.key = key
		end

		lang.set(self.to_locale(locale), value, author)
		lang
	end

	# возвращает хэш пар ключ=>значение, согласно заданной локали
	def self.all_head()
		unless @@all_head
			# извлекаем согласно локали и записываем в кэш
			by_key = {}
			self.all.each do |l|
				if(!by_key[l.key] || by_key[l.key].id < l.id)
					by_key[l.key] = l
				end
			end
			@@all_head = by_key
		end
		@@all_head
	end

	def self.clear_cache
		@@all_head = nil
	end


	# возвращает текстовое представление локали вида "ru", "en"
	def self.to_locale(locale)
		locale = locale.locale if locale.is_a?(User)
		locale = PUBLIC_CONFIG['DEFAULT_LOCALE'] unless locale
		locale.to_s
	end
end

class LangLocale < ActiveRecord::Base
end