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
				check_add_neighbour()
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
		refresh_energy()

		user = (@response['user'] ||= {})
		user.merge!(@user.to_json)


		@response['neighbours'] = []
		user_neighbours = @user.neighbours
		user_neighbours << @new_neighbour if @new_neighbour && !user_neighbours.index{|assoc| assoc.friend_uid.to_s == @new_neighbour.friend_uid.to_s }
		user_neighbours.each do |friend_assoc|
			next unless self.request_friend_ids.include?(friend_assoc.friend_uid)
			friend = friend_assoc.friend
			@response['neighbours'] << friend.to_short_json if friend
		end

		@response['session'] = true
	end

	protected
	def create_user
		# необходимые поля для создания: :uid, :net (, :first_name, :last_name)
		@json['user']['uid'] = @params['uid'].to_s # не даем возможности использовать разные значнеия uid,net в @params и @params['user']
		@json['user']['net'] = @params['net']
		#@user = User.find_by_uid(@params['uid'], @params['net'])
		@user = User.new(@json['user'])
		@user.attributes = CONFIG['init_user']
		# добавляем в ответ информацию о созданном пользователе
		@response['user'] = {'uid' => @user.uid, 'new' => true}
	end

	def check_referer_reward
		referer = @json['referer']
		if(referer && referer.to_s.length > 0 && referer.to_s != '0')
			invitator = User.where(:uid => referer.to_s).first(:select => User::SHORT_SELECT.dup << ', friends_invited, roll, rewards, money')
			if invitator
				invitator.friends_invited += 1
				invitator.money += PUBLIC_CONFIG['INVITE_REWARD_MONEY'].to_i
				reward = ServerLogic.checkAddReward(invitator, nil, nil, Reward::TYPE_REFERER, invitator.friends_invited)
				if reward
					reward.flag |= RewardInstance::FLAG_NEED_SHOW
					invitator.rewards[reward.id.to_s]['flag'] = reward.flag # записать в базу flag
					@response['invitator.reward'] = reward.to_json
				end
				check_add_neighbour(invitator)
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

	# выдать энергию
	def refresh_energy()
		if(@user.energy_last_gain)
			@user.energy_with_gain(true)
		else
			@user.gain_energy()
		end
	end

	def request_friend_ids
		@friend_ids ||= (@json['friendIds'] || []).map(&:to_s)
	end

	def check_add_neighbour(referer = nil)
		referer_uid = @json['referer']
		if(referer_uid && referer_uid.to_s.length > 0 && referer_uid.to_s != '0' && @json['add_neighbour'])
			referer = User.where(:uid => referer_uid.to_s).first(:select => User::SHORT_SELECT) unless referer
			add_neighbour(referer)
		end
	end

	def add_neighbour(friend)
		friend_assoc = friend.user_friends.where(:friend_uid => @user.uid.to_s).limit(1).first
		user_assoc = @user.user_friends.where(:friend_uid => friend.uid.to_s).limit(1).first

		unless user_assoc # TODO
			user_assoc = @user.user_friends.build(:friend_uid => friend.uid.to_s)
		end

		if user_assoc
			# в соседи
			user_assoc.accepted = true
			save(user_assoc)
			if friend_assoc
				friend_assoc.accepted = true
				save(friend_assoc)
			else
				friend.user_friends.build(:friend_uid => @user.uid, :accepted => true)
				save(friend)
			end
			@new_neighbour = user_assoc
		elsif !friend_assoc
			friend.user_friends.build(:friend_uid => @user.uid)
			save(friend)
		end
	end
end