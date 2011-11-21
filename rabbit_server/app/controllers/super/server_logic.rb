class ServerLogic
	class << self
=begin
		Начислить (если необходимо) награды за прохождение уровня
		@param levelInstance
=end
		def addRewardsToLevelInstance(user, levelInstance)
			reward = nil;
			selectedReward = nil;

			return [] unless levelInstance.success # Если уровень пройден с проигрышем, ничего не делаем

			# получить инфу по прошлому лучшему прохождению уровня (если таковое имеется)
			lastLevelInstance = user.get_level_instance_by_number(levelInstance.levelDef.number)

			levelConditions = levelInstance.levelDef.conditions_to_hash
			
			# проверяем, что уровень действительно пройден (судя по времени прох-я и морковкам)
			#var levelCarrotMin:int = XmlController.instance.calculateMinCarrots(levelInstance.levelDef);
			#if(levelConditions['time'] < levelInstance.timeSpended * 0.001 
			#	|| levelCarrotMin > levelInstance.carrotHarvested)
			#{
			#	return [];// Если уровень пройден с проигрышем, ничего не делаем
			#}

			# *** T I M E
			if(levelConditions['fastTime'] && levelConditions['fastTime'].to_i >= levelInstance.timeSpended * 0.001)#если прошел быстрее fastTime
				if(lastLevelInstance == nil ||# если ранее уровень не проходил
						(levelConditions['fastTime'].to_i < lastLevelInstance.timeSpended \
								&& lastLevelInstance.timeSpended < levelInstance.timeSpended))# или проходил медленнее, чем fastTime
					# выдать ревард за скорость
					checkAddReward(user, levelInstance, lastLevelInstance, Reward::TYPE_FAST_TIME);
				end
			end

			# *** ALL_CARROT
			levelCarrotMiddle = XmlController.instance.carrot_middle(levelInstance.levelDef);
			levelCarrotMax = XmlController.instance.carrot_max(levelInstance.levelDef);
			if(levelInstance.carrotHarvested >= levelCarrotMiddle && # если собрано морковок не мнее, чем для получения 2-х звезд
					lastLevelInstance == nil)  # ранее уровень не проходили
				if(
						(levelInstance.carrotHarvested >= levelCarrotMax && user.get_roll() > 0.1) ||
						(user.get_roll() > 0.8)
					)
					checkAddReward(user, levelInstance, lastLevelInstance, RewardDef::TYPE_ALL_CARROT);
				end
			end

			# если левел пройден впервые или с большим кол-ком собраннных морковок, записываем diff (иначе 0)
			carrotIncrement = (lastLevelInstance == nil ? levelInstance.carrotHarvested :
											Math.max(0, levelInstance.carrotHarvested - lastLevelInstance.carrotHarvested))

			# *** CARROT_PACK (получил очередной уровень по мороквкам: интегрально)
			if(carrotIncrement > 0)
				selectedReward = nil;
				RewardManager.instance.get_by_type(Reward::TYPE_CARROT_PACK).each do |reward|
					if(reward.degree <= (user.score + carrotIncrement) && (selectedReward == nil || selectedReward.degree < reward.degree))
						selectedReward = reward;
					end
				end
				if(selectedReward)
					checkAddReward(user, levelInstance, lastLevelInstance, Reward::TYPE_CARROT_PACK, selectedReward.degree);
				end
			end

			# *** CARROD INCREMENT (увеличить общий счетчик морковок)
			user.score = user.score + carrotIncrement if(carrotIncrement > 0)

			# *** LEVEL INCREMENT (увеличть левел)
			if(lastLevelInstance == nil)
				# stub, на сервере действительно пишется в базу
				user.level = levelInstance.levelDef.number if user.level < levelInstance.levelDef.number
			else
				# присвоив новому макс. значения
				levelInstance.carrotHarvested = Math.max(lastLevelInstance.carrotHarvested, levelInstance.carrotHarvested);
				levelInstance.timeSpended = Math.min(lastLevelInstance.timeSpended, levelInstance.timeSpended);

				# вырезать старый инстанс
				user.rewards[levelInstance.number] = nil
			end

			user.add_level_instance(levelInstance);

			levelInstance.rewards.dup;
		end

=begin
		Выдать ревард конкретного типа (если имеется ревард нужного типа, ранее не выданный)
		@param levelInstance
		@param rewardType "time"
		@param degree какую величину реварда достиг юзер на данный момент
		@param params
		@return выдан ли ревард
=end
		def checkAddReward(user, levelInstance, lastLevelInstance, rewardType, degree = 0, params = nil)
			reward = nil;
			availableRewards = [];

			RewardManager.instance.get_by_type(rewardType).each do |r|
				if r.degree == degree
					unless user.rewards[r.id]
						availableRewards << r
					end
				end
			end

			if(availableRewards.length > 0)
				reward = availableRewards[(user.get_roll() * availableRewards.length).to_i];
				levelInstance.rewards << reward;
				user.add_reward(reward);
			end

			reward
		end

=begin
		 Без проверок добавить ревард юзеру
		 @param user
		 @param reward
		 @param levelInstance
=end
		def addReward(user, reward, levelInstance)
			# не производит вычисление координат
			rewardInstance = RewardInstance.new(reward)
			levelInstance.rewards << rewardInstance;
			user.add_reward(rewardInstance);
		end
	end
end
