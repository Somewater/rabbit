module Gamedesign

	# Статистика по средним парамтерам прохождения уровней
	def self.level_stat(all_levels = false, all_versions = true, conditions = nil)
		conditions = 'net=2' unless conditions
		level_stat = {}
		user_stat = {}
		persents = {}
		
		head_levels = Level.all_head
		max_head_level = 0
		head_levels_by_id = {}
		head_levels.each do |l| 
		  next if !all_levels && l.number > 99
			head_levels_by_id[l.number.to_i] = l
			max_head_level = l.number.to_i if l.number.to_i > max_head_level
		end

		users_count = User.count(:conditions => conditions)
		iterator = 0
		User.find(:all, :conditions => conditions).each do |user|
			levels = user.level_instances
			levels.each do |number, level|
				next if !all_levels && number.to_i > 99
				next if !all_versions && head_levels_by_id[number.to_i].version > level['v'].to_i
				level_stat[number.to_i] = {:carrot => 0, :time => 0, :counter => 0, :time_min => 9999999, :carrot_max => 0, :star => 0} unless level_stat[number.to_i]
				stat = level_stat[number.to_i]
				stat[:carrot] += level['c']
				stat[:time] += level['t']
				stat[:star] += level['s']
				stat[:counter] += 1
				stat[:time_min] = level['t'] if level['t'] < stat[:time_min]
				stat[:carrot_max] = level['c'] if level['c'] > stat[:carrot_max]
			end
			user_stat[user.level] = 0 unless user_stat[user.level]
			user_stat[user.level] += 1
			iterator += 1
			persent = (iterator.to_f / users_count * 100).to_i
			unless persents[persent]
				puts "#{persent}%"
				persents[persent] = true
			end
		end

		puts "\n\n**********************\n\r\tSTATISTIC\n**********************"
		puts "\n***\tLEVELS\t***"
		(1..max_head_level).each do |number|
			stat = level_stat[number.to_i]
			next unless stat
			next unless head_levels_by_id[number]
			stat[:time] /= stat[:counter]
			stat[:carrot] /= stat[:counter]
			stat[:star] = ((stat[:star] / stat[:counter].to_f) * 100).to_i / 100.0
			pass_users = 0
			user_stat.each{|k,v| pass_users += v.to_i if k.to_i >= number }

			puts "LEVEL #{number} - #{head_levels_by_id[number].description.gsub("\n\r",'')}"
			puts "users: #{user_stat[number.to_i]}\tpass: #{pass_users}\tavg time: #{stat[:time]}\tmin time: #{stat[:time_min]}\tavg carrot: #{stat[:carrot]}\tmax carrot: #{stat[:carrot_max]}\tavg stars: #{stat[:star]}"
			head_levels_by_id[number.to_i].conditions_to_hash.each do |key,value|
				puts "#{key}=#{value}  "
			end
			puts "\n"
		end
	end
end
