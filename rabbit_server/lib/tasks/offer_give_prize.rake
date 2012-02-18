module OffersGivePrize
	def self.execute(customize_type, customize_id)
		users_affected = 0
		prizes = 0
		User.find(:all).each do |user|
			if user.offers > 49
				user.set_customize(customize_type, customize_id)
				prizes += 1
			end

			user.offers = 0
			user['offer_instances'] = nil
			user.save
			users_affected += 1
		end

		puts "=====\nUSERS AFFECTED #{users_affected}\n======"
		puts "===\nPRIZES #{prizes}\n==="
	end
end