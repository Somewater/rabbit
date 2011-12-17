package com.somewater.rabbit.application.commands {
	import com.somewater.rabbit.storage.Config;
	import com.somewater.rabbit.storage.GameUser;
	import com.somewater.rabbit.storage.RewardLevelDef;

	public class OpenRewardLevelCommand implements ICommand{

		private var gameUser:GameUser;

		public function OpenRewardLevelCommand(gameUser:GameUser) {
			this.gameUser = gameUser;
		}

		public function execute():void {
			if(gameUser.itsMe())
			{
				// отпозиционировать реварды с нулевой позицией
				Config.application.positionizeRewards(gameUser);
				directlyStart();
			}
			else
			{
				// получить реварды с сервера, если необходимо
			}
		}

		private function directlyStart():void
		{
			Config.application.startGame(new RewardLevelDef(gameUser));
		}
	}
}
