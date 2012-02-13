module OffersDbStringErrorFix
	def self.execute()
		users_affected = 0
		User.find(:all).each do |user|
			if user['offer_instances']
				str = user['offer_instances']
				offer_instances = {}
				str.scan(/1\d{9}/) do |m|
					offer_instances[m] = {}
				end
				p "===================== user id= #{user.id} / #{user.uid}"
				p user['offer_instances']
				p ' => '
				user['offer_instances'] = JSON.fast_generate(offer_instances)
				p user.offer_instances
				user.save
				users_affected += 1
			end
		end

		puts "=====\nUSERS AFFECTED #{users_affected}\n======"
	end
end