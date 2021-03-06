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
			
			# проверяем, что уровень действительно пройден (судя по морковкам)
			levelCarrotMin = XmlController.instance.carrot_min(levelInstance.levelDef)
			if(levelCarrotMin > levelInstance.carrotHarvested)
				levelInstance.success = false
				return [] # Если уровень пройден с проигрышем, ничего не делаем
			end
			raise LogicError, "Unbelievable carrot harvested value = #{levelInstance.carrotHarvested}" if(levelInstance.carrotHarvested > XmlController.instance.carrot_all(levelInstance.levelDef))
#			raise LogicError, "Inaccessible level ##{levelInstance.levelDef.number} from #{user.level}" if user.level < levelInstance.levelDef.number

			# *** T I M E
			if(levelConditions['fastTime'] && levelConditions['fastTime'].to_i >= levelInstance.timeSpended)#если прошел быстрее fastTime
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
			if((levelInstance.levelDef.number == 1 || levelInstance.carrotHarvested >= levelCarrotMiddle) && # если собрано морковок не мнее, чем для получения 2-х звезд
					lastLevelInstance == nil)  # ранее уровень не проходили
				if(
						(levelInstance.levelDef.number == 1 || # на первом (туториальном) уровне всегда выдаем награду, если он проходится впервые
						 levelInstance.carrotHarvested >= levelCarrotMax && user.get_roll() > 0.1) ||
						(levelInstance.carrotHarvested < levelCarrotMax && user.get_roll() > 0.7)
					)
					checkAddReward(user, levelInstance, lastLevelInstance, Reward::TYPE_ALL_CARROT);
				end
			end

			# если левел пройден впервые или с большим кол-ком собраннных морковок, записываем diff (иначе 0)
			carrotIncrement = (lastLevelInstance == nil ? levelInstance.carrotHarvested :
											[0, levelInstance.carrotHarvested - lastLevelInstance.carrotHarvested].max)

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
				if user.level < levelInstance.levelDef.number + 1
					user.level = levelInstance.levelDef.number + 1
					user.gain_energy()
				end
			else
				# присвоив новому макс. значения
				levelInstance.data = {'c' => [lastLevelInstance.carrotHarvested, levelInstance.carrotHarvested].max,
										't' => [lastLevelInstance.timeSpended, levelInstance.timeSpended].min}
			end

			# CALCULATE STARS
			levelInstance.stars = levelInstance.carrotHarvested >= levelCarrotMax ? 3 : (levelInstance.carrotHarvested >= levelCarrotMiddle ? 2 : 1)
			starsIncrement = (lastLevelInstance == nil ? levelInstance.stars :
											[0, levelInstance.stars - lastLevelInstance.stars].max)
			user.stars = user.stars + starsIncrement if (starsIncrement > 0)

			user.add_level_instance(levelInstance);

			levelInstance.rewards.dup;
		end

=begin
		Выдать ревард конкретного типа (если имеется ревард нужного типа, ранее не выданный)
		@param levelInstance
		@param rewardType "time"
		@param degree какую величину реварда достиг юзер на данный момент
		@param params
		@return выдан ли ревард (возвращает LevelInstance или nil)
=end
		def checkAddReward(user, levelInstance, lastLevelInstance, rewardType, degree = 0, params = nil)
			reward = nil;
			availableRewards = [];

			RewardManager.instance.get_by_type(rewardType).each do |r|
				if r.degree == degree
					unless user.rewards[r.id.to_s]
						availableRewards << r
					end
				end
			end

			if(availableRewards.length > 0)
				# сортируем по id
				if levelInstance && levelInstance.number > 5 && user.get_roll() < 0.5
					return nil
				end
				availableRewards.sort!{|x,y| x.id <=> y.id }
				reward = availableRewards[(user.get_roll() * availableRewards.length).to_i];
				return addReward(user, reward, levelInstance)
			end

			nil
		end

=begin
		 Без проверок добавить ревард юзеру
		 @param user
		 @param reward
		 @param levelInstance
		 @return LevelInstance
=end
		private
		def addReward(user, reward, levelInstance)
			# не производит вычисление координат
			rewardInstance = RewardInstance.new(reward, levelInstance)
			levelInstance.rewards << rewardInstance if levelInstance
			user.add_reward_instance(rewardInstance);
			rewardInstance
		end
	end
end
