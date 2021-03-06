namespace :lang do
	desc "Lang DB generationg from lang.*"
	task :from_txt, [:locale] => :environment do |task, args|
		locale = args[:locale] || 'ru'
		counter = 0
		iterate_locale_txt(locale) do |key, value, part|
			lang = Lang.create(key, value, locale, 'rake')
			lang.part = part
			lang.save
			counter += 1
		end
		puts "Created #{counter} lang entries"
	end

	desc "Lang DB generationg from level.description"
	task :from_levels, [:locale] => :environment do |task, args|
		locale = args[:locale] || 'ru'
		counter = 0
		iterate_levels_db() do |number, title, description, author|
			key = "LEVEL_TITLE_#{number}"
			lang = Lang.create(key, title, locale, author)
			lang.part = 'LEVELS'
			lang.comment = "Level #{number} title"
			lang.save

			key = "LEVEL_DESC_#{number}"
			lang = Lang.create(key, description, locale, author)
			lang.part = 'LEVELS'
			lang.comment = "Level #{number} description"
			lang.save

			counter += 2
		end

		puts "Created #{counter} lang entries (for #{(counter / 2)} levels)"
	end

	desc "Generate from txt locale files and levels DB entries"
	task :generate => [:from_txt, :from_levels] do
		puts "Success"
	end

	desc "Only add new entries"
	task :add_new => :environment do
		locale = 'ru'
		counter = 0
		iterate_locale_txt(locale) do |key, value, part|
			lang = Lang[key]
			unless lang
				lang = Lang.create(key, value, locale, 'rake')
				lang.part = part
				lang.save
				counter += 1
			end
		end
		iterate_levels_db() do |number, title, description, author|
			key = "LEVEL_TITLE_#{number}"
			lang = Lang[key]
			unless lang
				lang = Lang.create(key, title, locale, author)
				lang.part = 'LEVELS'
				lang.comment = "Level #{number} title"
				lang.save
				counter += 1
			end

			key = "LEVEL_DESC_#{number}"
			lang = Lang[key]
			unless lang
				lang = Lang.create(key, description, locale, author)
				lang.part = 'LEVELS'
				lang.comment = "Level #{number} description"
				lang.save
				counter += 1
			end
		end
		puts "Created #{counter} lang entries"
	end

	desc "Delete all DB entries"
	task :delete_all, [:a_you_shure] => :environment do |task, args|
		raise "type `rake lang:delete_all[yes]`" unless args[:a_you_shure].to_s == 'yes'
		puts "Deleted Lang: #{Lang.delete_all}, LangLocale: #{LangLocale.delete_all}"
	end

	desc "Create empty LangLocale entities"
	task :add_locale, [:locale] => :environment do |task, args|
		locale = args[:locale].to_s
		raise "Wrong locale" if locale == nil || locale.size != 2
		counter = 0
		Lang.all_head.each do |key, lang|
			unless lang.locales[locale]
				puts "CREATE #{key}"
				lang.set(locale, nil, 'rake')
				counter += 1
			end
		end
		puts "Locale '#{locale}' process completed. Created #{counter} entries"
	end

	# yield(key, value, part)
	def iterate_locale_txt(locale)
		File.open("#{ROOT}/src/locale/#{locale}.txt") do |f|
			part = nil
			f.read.each_line do |line|
				if(line[0] == '#')
					next if line[0,2] == '#!'
					line.gsub!('#','')
					if(line.gsub(/\s/,'').size > 0)
						part = line.strip
					end
				else
					key = line[0,line.index('=')]
					value = line[line.index('=') + 1,10_000].strip
					yield(key, value, part)
				end
			end
		end
	end

	# yield(number, title, description, l.author)
	def iterate_levels_db()
		Level.all_head.each do |l|
			number = l.number
			if(number <= 99)
				line = l.description.strip
				if(line.index('--'))
					title = line[0,line.index('--')].strip
					description = line[line.index('--') + 2,10_000].strip
				else
					title = description = line
				end

				yield(number, title, description, l.author)
			end
		end
	end
end