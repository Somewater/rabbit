class InitializeController < BaseUserController

	def authorized
		@response['rewards'] = [] # сюда по ходу проверок будем вписывать ревары, выданные оффлайн или за заход в игру
		@response['unixtime'] = Application.time.to_i # секунды, unixtime

		if @params['uid'] && @params['uid'].to_s.size > 0 && @params['uid'].to_s != 'null' && @params['uid'].to_s != '0'
			# базовая реализация поиска юзера
			begin
				super
				check_familiar_reward()
				check_pending_referer_reward()
			rescue AuthError
				# создать юзера
				create_user()
				check_referer_reward()
			end
		elsif(@api.can_allocate_uid)
			# сначала вычислим ранее не применяемый :uid
			max_id = (User.maximum(:id) || 0) + 1
			max_id = "#{@params['net']}-#{max_id}"# создаем  uid для несоциальной сети, на основе комбинации id и net
			raise AuthError, "Already used uid = #{max_id}" if User.find_by_uid(max_id, @params['net'])
			@json['user']['uid'] = @params['uid'] = max_id.to_s
			create_user()
			check_referer_reward()
		else
			raise AuthError, 'Undefined uid from net with defined uids'
		end
	end

	def process
		user = (@response['user'] ||= {})
		user.merge!(@user.to_json)

		friendIds = @json['friendIds'] || []
		@response['friends'] = []
		friendIds.each do |friend_uid|
			friend = User.find_by_uid(friend_uid, @params['net'])
			@response['friends'] << friend.to_short_json if friend
		end

		@response['session'] = true
	end

	private
	def create_user
		# необходимые поля для создания: :uid, :net (, :first_name, :last_name)
		@json['user']['uid'] = @params['uid'] # не даем возможности использовать разные значнеия uid,net в @params и @params['user']
		@json['user']['net'] = @params['net']
		#@user = User.find_by_uid(@params['uid'], @params['net'])
		@user = User.new(@json['user'])
		@user.attributes = CONFIG['init_user']
		# добавляем в ответ информацию о созданном пользователе
		@response['user'] = {'uid' => @user.uid, 'new' => true}
	end

	def check_referer_reward
		if(@json['referer'] && @json['referer'].to_s.length > 0 && @json['referer'].to_s != '0')
			invitator = User.find_by_uid(@json['referer'], @user.net)
			if invitator
				invitator.friends_invited += 1
				reward = ServerLogic.checkAddReward(invitator, nil, nil, Reward::TYPE_REFERER, invitator.friends_invited)
				if reward
					reward.flag |= RewardInstance::FLAG_NEED_SHOW
					invitator.rewards[reward.id.to_s]['flag'] = reward.flag # записать в базу flag
					@response['invitator.reward'] = reward.to_json
				end
				save(invitator)
			end
		end
	end

	def check_familiar_reward
		# все проверки на увеличени еи обнуление счетчика при условии, что во время прошлого захода был другой день
		if @user.updated_at && @user.updated_at.yday != Application.time.yday
			if(Application.time.yday - @user.updated_at.yday == 1 || Application.time.yday == 1 && @user.updated_at.yday == 366)
				@user.day_counter += 1
				reward = ServerLogic.checkAddReward(@user, nil, nil, Reward::TYPE_FAMILIAR, @user.day_counter)
				if reward
					@user.day_counter = 0
					@response['rewards'] << reward.to_json
				end
			else
				# обнуляем сечтчик. если  человек просрочил заход в игру
				@user.day_counter = 0
			end
		end
	end

	# проверяем, были ли выданы юзеру реварды за пригл-е друзей, пока он был оффлайн
	def check_pending_referer_reward
		@user.rewards.each do |id, reward|
			if reward['flag']
				@response['rewards'] << reward
			end
		end
		@user.clear_all_flags()
	end
end