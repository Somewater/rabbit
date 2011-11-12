package com.somewater.rabbit.application {
	import com.somewater.rabbit.storage.GameUser;
	import com.somewater.rabbit.storage.LevelInstanceDef;
	import com.somewater.rabbit.storage.RewardDef;
	import com.somewater.rabbit.xml.XmlController;

	/**
	 * Класс содержит чистую логику, аналогичную для сервера и клиента
	 */
	public class ServerLogic {

		/**
		 * Начислить (если необходимо) награды за прохождение уровня
		 * @param levelInstance
		 */
		public static function addRewardsToLevelInstance(user:GameUser, levelInstance:LevelInstanceDef):void
		{
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
					addReward(user, levelInstance, RewardDef.TYPE_FAST_TIME);
			}

			// *** ALL_CARROT
			if(XmlController.instance.calculateCarrots(levelInstance.levelDef) == levelInstance.carrotHarvested && // если собраны все морковки уровня
					(lastLevelInstance == null ||  // ранее уровень не проходили
							lastLevelInstance.carrotHarvested < levelInstance.carrotHarvested) // или проходили с меньшим кол-вом морковки
					)
			{
				addReward(user, levelInstance, RewardDef.TYPE_ALL_CARROT);
			}

			// если левел пройден впервые или с большим кол-ком собраннных морковок, записываем diff (иначе 0)
			levelInstance.carrotIncrement = (lastLevelInstance == null ? levelInstance.carrotHarvested :
											Math.max(0, levelInstance.carrotHarvested - lastLevelInstance.carrotHarvested))

			// *** CARROT_PACK (получил очередной уровень по мороквкам: интегрально)
			if(levelInstance.carrotIncrement > 0)
			{
				// todo: проверить по конфигу carrot_pack, не достигнута ли новая награда
			}

			// *** CARROD INCREMENT (увеличить общий счетчик морковок)
			if(levelInstance.carrotIncrement > 0)
				user.score += levelInstance.carrotIncrement;

			// *** LEVEL INCREMENT (увеличть левел)
			if(lastLevelInstance == null)
			{
				// stub, на сервере действительно пишется в базу
				//UserProfile.instance.levelNumber = levelInstance.levelDef.number;
			}
		}

		/**
		 * Выдать ревард конкретного типа (если имеется ревард нужного типа, ранее не выданный)
		 * @param levelInstance
		 * @param rewardType "time"
		 */
		private static function addReward(user:GameUser, levelInstance:LevelInstanceDef, rewardType:String):void
		{
			//levelInstance.rewards.push(RewardDef.REWARD_FAST_TIME);
			throw new Error('Not implemented');
		}
	}
}
