class FriendVisitRewardController < BaseUserController

	include RequestSecurity

	# выдать ревард за посещение друга
	def process
		friend_uid = @json['friend_id'] || @json['friend_uid']
		# проверить, что речь идет о друге
		user_friend = @user.neighbours.where(:friend_uid => friend_uid.to_s).first
		raise LogicError, "User ##{friend_uid} not friend for ##{@user.uid}" unless user_friend

		# проверить, что в данный момент можно собрать награду
		if !user_friend.last_daily_bonus ||
				user_friend.last_daily_bonus + PUBLIC_CONFIG['FRIEND_DAILY_BONUS_INTERVAL'].to_i - CONFIG['friend_daily_bonus']['time_buffer'].to_i < Application.time
			# выдать награду
			@user.money += PUBLIC_CONFIG['VISIT_REWARD_MONEY'].to_i

			# отметить время сбора награды
			user_friend.last_daily_bonus = Application.time.dup

			@response['success'] = true
		else
			@response['success'] = false
		end
		@response['money'] = @user.money
		@response['next_reward_time'] = (user_friend.last_daily_bonus + PUBLIC_CONFIG['FRIEND_DAILY_BONUS_INTERVAL'].to_i).to_i

		self.save(user_friend)
	end
end