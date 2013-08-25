class AddNeighboursController < BaseUserController

	def process
		@json['friend_uids'].split(',').each do |friend_uid|
			user_assoc = @user.user_friends.where(:friend_uid => friend_uid).limit(1).first

			if user_assoc && user_assoc.accepted
				# Already neighbours
				@response['ignored_friend_ids'] ||= []
				@response['ignored_friend_ids'] << friend_uid
				next
			end

			@friend = User.where(:uid => friend_uid.to_s).first(:select => User::SHORT_SELECT)
			friend_assoc = @friend.user_friends.where(:friend_uid => @user.uid).limit(1).first

			unless friend_assoc
				friend_assoc = @friend.user_friends.build(:friend_uid => @user.uid)
			end

			neighbour_created = false
			if friend_assoc && user_assoc
				user_assoc.accepted = true
				friend_assoc.accepted = true
				save(user_assoc)
				save(friend_assoc)
				neighbour_created = true
			elsif friend_assoc.new_record?
				save(friend_assoc)
			else
				# "Neighbour request already created"
				@response['ignored_friend_ids'] ||= []
				@response['ignored_friend_ids'] << friend_uid
				next
			end

			if neighbour_created
				@response['new_friends'] ||= []
				@response['new_friends'] << @friend.to_short_json
			end
		end

		@response['success'] = 1
	end

end