namespace :fixes do
	desc "Set 0,0 reward coordinates, if coordinates out of field"
	task :fix_out_of_field => :environment do

		reward_counter = 0
		user_counter = 0

		check = lambda do |user, reward_id|
			r = user.rewards
			reward_id = reward_id.to_s
			if(r[reward_id] && r[reward_id]['x'] > 7)
				reward_counter += 1
				r[reward_id]['x'] = 0
				r[reward_id]['y'] = 0
				true
			else
				false
			end
		end

		iterate_users do |u|
			r = u.rewards
			need_save = false
			need_save = true if check.call(u, 75)
			need_save = true if check.call(u, 33)
			if need_save
				u.save
				user_counter += 1
			end
		end
		puts "User rewards fixed: #{reward_counter}. Users fixed: #{user_counter}"
	end

	def iterate_users(&block)
		users_count = User.count()
		iterator = 0
		persents = {}
		User.find(:all).each do |user|
			#PROCESS
			block.call(user)

			# SET PERSENT
			iterator += 1
			persent = (100 * iterator.to_f / users_count.to_f).to_i
			unless persents[persent]
				puts "[USERS] #{persent}%"
				persents[persent] = true
			end
		end
	end
end