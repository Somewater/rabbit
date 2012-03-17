class FriendVisitRewardController < BaseUserController

	include RequestSecurity

	# выдать ревард за посещение друга
	def process
		friend_id = @json['friend_id']
		# проверить, что речь идет о друге
		storage = FriendStorage.find_by_user(friend_id, @params['net'])
		raise LogicError, "User ##{friend_id} not friend for ##{@user.uid}" unless storage && storage.include?(@user)

		# проверить, что в данный момент можно собрать награду
		if Application.time.yday != storage.last_day.to_i || !storage.rewarded?(@user)
			# выдать награду
			@user.money += PUBLIC_CONFIG['VISIT_REWARD_MONEY'].to_i

			# отметить время сбора награды
			if(storage.last_day == Application.time.yday)
				storage.rewarded = (storage.rewarded << @user.uid)
			else
				storage.last_day = Application.time.yday
				storage.rewarded = [@user.uid]
			end

			@response['success'] = true
		else
			@response['success'] = false
		end
		@response['money'] = @user.money

		self.save(storage)
	end
end