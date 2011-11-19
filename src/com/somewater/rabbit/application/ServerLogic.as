package com.somewater.rabbit.application {
	import com.somewater.rabbit.application.RewardManager;
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
		 * @return массив выданных ревардов (array of LevelInstanceDef)
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
						(levelInstance.carrotHarvested >= levelCarrotMax && user.getRoll() > 0.1) ||
						(user.getRoll() > 0.8)
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
				for each(reward in RewardManager.instance.getByType(RewardDef.TYPE_ALL_CARROT))
				{
					if(reward.degree <= (user.score + carrotIncrement) && (selectedReward == null || selectedReward.degree < reward.degree))
						selectedReward = reward;
				}
				if(selectedReward)
					checkAddReward(user, levelInstance, lastLevelInstance, RewardDef.TYPE_ALL_CARROT, selectedReward.degree);
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

				// вырезать старый инстанс
				var lastLevelInstanceIndex:int = user.levelInstances.indexOf(lastLevelInstance);
				user.rewards.splice(lastLevelInstanceIndex,  1);
			}

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
		private static function checkAddReward(user:GameUser, levelInstance:LevelInstanceDef, lastLevelInstance:LevelInstanceDef, rewardType:String, degree:int = 0, params:Object = null):Boolean
		{
			var reward:RewardDef;
			var availableRewards:Array = [];

			for each(reward in RewardManager.instance.getByType(rewardType))
				if(reward.degree == degree)
					if(user.rewards.every(function(elem:RewardInstanceDef, ...args):Boolean{ return elem.id != reward.id }))
					{
						availableRewards.push(reward);
					}

			if(availableRewards.length)
			{
				reward = availableRewards[int(user.getRoll() * availableRewards.length)];
				addReward(user, reward, levelInstance);
			}else
				reward = null;

			return reward != null;
		}

		/**
		 * Без проверок добавить ревард юзеру
		 * @param user
		 * @param reward
		 * @param levelInstance
		 */
		private static function addReward(user:GameUser, reward:RewardDef, levelInstance:LevelInstanceDef):void
		{
			var rewardInstance:RewardInstanceDef = new RewardInstanceDef(reward);
			var counter:int = 1000;
			var size:Point = rewardInstance.size;
			var rect:Rectangle = new Rectangle(0, 0, size.x, size.y);

			cycle:
			while(counter > 0)
			{
				// генериурем рандомную позицию на поляне
				var position:Point = new Point(
						int(user.getRoll() * RewardLevelDef.WIDTH  + 1 - size.x),
						int(user.getRoll() * RewardLevelDef.HEIGHT + 1 - size.y));

				// проверяем на пересечение с норой
				if(position.x < 3 && position.y < 3)
				{
					counter--;
					continue;
				}

				var userRewards:Array = user.rewards;
				for(var i:int = 0; i < userRewards.length; i++)
				{
					counter--;
					var userReward:RewardInstanceDef = userRewards[i];
					var userRewardSize:Point = userReward.size;
					if(new Rectangle(userReward.x,  userReward.y, userRewardSize.x, userRewardSize.y).intersects(rect))
					{
						continue cycle;
					}
				}

				rewardInstance.x = position.x;
				rewardInstance.y = position.y;
				break;
			}

			levelInstance.rewards.push(rewardInstance);
			user.addReward(rewardInstance);
		}
	}
}
