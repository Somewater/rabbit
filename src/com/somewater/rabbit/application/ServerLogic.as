package com.somewater.rabbit.application {
	import com.somewater.rabbit.storage.LevelInstanceDef;
	import com.somewater.rabbit.storage.RewardDef;
	import com.somewater.rabbit.storage.UserProfile;

	/**
	 * Класс содержит чистую логику, аналогичную для сервера и клиента
	 */
	public class ServerLogic {

		/**
		 * Начислить (если необходимо) награды за прохождение уровня
		 * @param levelInstance
		 */
		public static function addRewardsToLevelInstance(levelInstance:LevelInstanceDef):void
		{
			// получить инфу по прошлому лучшему прохождению уровня (если таковое имеется)
			var lastLevelInstance:LevelInstanceDef = UserProfile.instance.getLevelInsanceByNumber(levelInstance.levelDef.number);

			var levelConditions:Array = [];
			for (var key:String in levelInstance.levelDef.conditions)
				levelConditions[key] = levelInstance.levelDef.conditions[key];

			// T I M E
			if(levelConditions['fastTime'] && levelConditions['fastTime'] >= levelInstance.timeSpended * 0.001)
			{
				if(lastLevelInstance == null || lastLevelInstance.timeSpended < levelInstance.timeSpended)
					levelInstance.rewards.push(RewardDef.REWARD_FAST_TIME);
			}
		}
	}
}
