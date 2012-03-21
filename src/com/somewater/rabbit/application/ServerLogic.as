package com.somewater.rabbit.application {
	import com.somewater.rabbit.application.RewardManager;
	import com.somewater.rabbit.storage.Config;
	import com.somewater.rabbit.storage.GameUser;
	import com.somewater.rabbit.storage.LevelInstanceDef;
	import com.somewater.rabbit.storage.RewardDef;
	import com.somewater.rabbit.storage.RewardInstanceDef;
	import com.somewater.rabbit.storage.RewardLevelDef;
	import com.somewater.rabbit.xml.XmlController;

	import flash.geom.Point;
	import flash.geom.Rectangle;

	/**
	 * Класс содержит чистую логику, аналогичную для сервера и клиента
	 */
	public class ServerLogic {

		/**
		 * Начислить (если необходимо) награды за прохождение уровня
		 * @param levelInstance
		 * @return массив выданных ревардов (array of RewardInstanceDef)
		 */
		public static function addRewardsToLevelInstance(user:GameUser, levelInstance:LevelInstanceDef):Array
		{
			var reward:RewardDef;
			var selectedReward:RewardDef;

			if(!levelInstance.success)
				return [];// Если уровень пройден с проигрышем, ничего не делаем

			// получить инфу по прошлому лучшему прохождению уровня (если таковое имеется)
			var lastLevelInstance:LevelInstanceDef = user.getLevelInsanceByNumber(levelInstance.levelDef.number);

			var levelConditions:Array = [];
			for (var key:String in levelInstance.levelDef.conditions)
				levelConditions[key] = levelInstance.levelDef.conditions[key];
			
			// проверяем, что уровень действительно пройден (судя по морковкам)
			var levelCarrotMin:int = XmlController.instance.calculateMinCarrots(levelInstance.levelDef);
			if(levelCarrotMin > levelInstance.carrotHarvested)
			{
				levelInstance.success = false;
				return [];// Если уровень пройден с проигрышем, ничего не делаем
			}
			if(levelInstance.carrotHarvested > XmlController.instance.calculateCarrots(levelInstance.levelDef))
			{
				Config.application.fatalError('ERROR_INVALID_CARROT_HARVEST_VALUE');
				return null;
			}
			if(levelInstance.levelDef.number > user.levelNumber && !Config.memory['portfolioMode'])
			{
				Config.application.fatalError(Config.application.translate('ERROR_INACCESSIBLE_LEVEL',{'level':levelInstance.levelDef.number}));
				return null;
			}
			
			// *** T I M E
			if(levelConditions['fastTime'] && levelConditions['fastTime'] >= levelInstance.timeSpended * 0.001)//если прошел быстрее fastTime
			{
				if(lastLevelInstance == null ||// если ранее уровень не проходил
						(levelConditions['fastTime'] < lastLevelInstance.timeSpended
								&& lastLevelInstance.timeSpended < levelInstance.timeSpended))// или проходил медленнее, чем fastTime
					// выдать ревард за скорость
					checkAddReward(user, levelInstance, lastLevelInstance, RewardDef.TYPE_FAST_TIME);
			}

			// *** ALL_CARROT
			var levelCarrotMiddle:int = XmlController.instance.calculateMiddleCarrots(levelInstance.levelDef);
			var levelCarrotMax:int = XmlController.instance.calculateMaxCarrots(levelInstance.levelDef);
			if(levelInstance.carrotHarvested >= levelCarrotMiddle && // если собрано морковок не мнее, чем для получения 2-х звезд
					lastLevelInstance == null)  // ранее уровень не проходили
			{
				if(
						(levelInstance.number == 1 || // на первом (туториальном) уровне всегда выдаем награду, если он проходится впервые
						 levelInstance.carrotHarvested >= levelCarrotMax && user.getRoll() > 0.1) ||
						(levelInstance.carrotHarvested < levelCarrotMax && user.getRoll() > 0.7)
					)
				{
					checkAddReward(user, levelInstance, lastLevelInstance, RewardDef.TYPE_ALL_CARROT);
				}
			}

			// если левел пройден впервые или с большим кол-ком собраннных морковок, записываем diff (иначе 0)
			var carrotIncrement:int = (lastLevelInstance == null ? levelInstance.carrotHarvested :
											Math.max(0, levelInstance.carrotHarvested - lastLevelInstance.carrotHarvested))

			// *** CARROT_PACK (получил очередной уровень по мороквкам: интегрально)
			if(carrotIncrement > 0)
			{
				selectedReward = null;
				for each(reward in RewardManager.instance.getByType(RewardDef.TYPE_CARROT_PACK))
				{
					if(reward.degree <= (user.score + carrotIncrement) && (selectedReward == null || selectedReward.degree < reward.degree))
						selectedReward = reward;
				}
				if(selectedReward)
					checkAddReward(user, levelInstance, lastLevelInstance, RewardDef.TYPE_CARROT_PACK, selectedReward.degree);
			}

			// *** CARROD INCREMENT (увеличить общий счетчик морковок)
			if(carrotIncrement > 0)
				user.score += carrotIncrement;

			// *** LEVEL INCREMENT (увеличть левел)
			if(lastLevelInstance == null)
			{
				// stub, на сервере действительно пишется в базу
				//user.levelNumber = levelInstance.levelDef.number;
			}
			else
			{
				// присвоив новому макс. значения
				levelInstance.carrotHarvested = Math.max(lastLevelInstance.carrotHarvested, levelInstance.carrotHarvested);
				levelInstance.timeSpended = Math.min(lastLevelInstance.timeSpended, levelInstance.timeSpended);
			}

			// CALCULATE STARS
			levelInstance.stars = levelInstance.carrotHarvested >= levelCarrotMax ? 3 : (levelInstance.carrotHarvested >= levelCarrotMiddle ? 2 : 1)
			var starsIncrement:int = (lastLevelInstance == null ? levelInstance.stars :
											Math.max(0, levelInstance.stars - lastLevelInstance.stars))
			if(starsIncrement > 0)
				user.stars += starsIncrement;

			user.addLevelInstance(levelInstance);

			return levelInstance.rewards.slice();
		}

		/**
		 * Выдать ревард конкретного типа (если имеется ревард нужного типа, ранее не выданный)
		 * @param levelInstance
		 * @param rewardType "time"
		 * @param degree какую величину реварда достиг юзер на данный момент
		 * @param params
		 * @return выдан ли ревард
		 */
		public static function checkAddReward(user:GameUser, levelInstance:LevelInstanceDef, lastLevelInstance:LevelInstanceDef, rewardType:String, degree:int = 0, params:Object = null):RewardInstanceDef
		{
			var reward:RewardDef;
			var availableRewards:Array = [];
			var result:RewardInstanceDef;

			for each(reward in RewardManager.instance.getByType(rewardType))
				if(reward.degree == degree)
					if(user.rewards.every(function(elem:RewardInstanceDef, ...args):Boolean{ return elem.id != reward.id }))
					{
						availableRewards.push(reward);
					}

			if(availableRewards.length)
			{
				// сортируем по id
				availableRewards.sortOn(['id'], Array.NUMERIC)

				reward = availableRewards[int(user.getRoll() * availableRewards.length)];
				return addReward(user, reward, levelInstance);
			}else
				return null;
		}

		/**
		 * Найти позицию для реварда
		 * @param reward
		 * @param otherRewards
		 */
		public static function positionReward(rewardInstance:RewardInstanceDef, userRewards:Array):void
		{
			var counter:int = 100000;
			var size:Point = rewardInstance.size;
			var rect:Rectangle = new Rectangle(0, 0, size.x, size.y);

			cycle:
			while(counter > 0)
			{
				// генериурем рандомную позицию на поляне
				var position:Point = new Point(
						int(Math.random() * RewardLevelDef.WIDTH  + 1 - size.x),
						int(Math.random() * RewardLevelDef.HEIGHT + 1 - size.y));
				rect.x = position.x;
				rect.y = position.y;

				// проверяем на пересечение с норой (и дорожкой вокруг нее)
				if(position.x < 4 && position.y < 4)
				{
					counter--;
					continue;
				}

				// проверяем пересечение с дефолтной стартовой позицией кролика
				if(position.x == 3 && position.y == 2)
				{
					counter--;
					continue;
				}


				for(var i:int = 0; i < userRewards.length; i++)
				{
					counter--;
					var userReward:RewardInstanceDef = userRewards[i];
					var userRewardSize:Point = userReward.size;
					var intersect:Rectangle;
					if(userRewards.length < 60 && counter > 0)// square 9x9=81, minus 9 on hole, minus ~10 on big rewards
					{
						// на относительно пустой поляне пытаемся проставить награды "шашками", 
						// т.е. чтобы меж ними были робелы для хождения кроля
						intersect = new Rectangle(userReward.x - 1,  userReward.y - 1, userRewardSize.x + 1, userRewardSize.y + 1).intersection(rect)
					}
					else
					{
						// просто пытаемся найти незанятую позицию
						intersect = new Rectangle(userReward.x,  userReward.y, userRewardSize.x, userRewardSize.y).intersection(rect)
					}
					if(intersect.width > 0 && intersect.height > 0)
					{
						continue cycle;
					}
				}

				rewardInstance.x = position.x;
				rewardInstance.y = position.y;
				break;
			}
		}

		/**
		 * Без проверок добавить ревард юзеру
		 * @param user
		 * @param reward
		 * @param levelInstance
		 */
		private static function addReward(user:GameUser, reward:RewardDef, levelInstance:LevelInstanceDef):RewardInstanceDef
		{
			var rewardInstance:RewardInstanceDef = new RewardInstanceDef(reward);

			positionReward(rewardInstance, user.rewards);

			if(levelInstance)
				levelInstance.rewards.push(rewardInstance);
			user.addRewardInstance(rewardInstance);

			return rewardInstance;
		}


	}
}
