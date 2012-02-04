package com.somewater.rabbit.application.commands {
	import com.somewater.rabbit.application.AppServerHandler;
	import com.somewater.rabbit.application.ImaginaryGameUser;
	import com.somewater.rabbit.storage.Config;
	import com.somewater.rabbit.storage.GameUser;
	import com.somewater.rabbit.storage.RewardLevelDef;
	import com.somewater.storage.Lang;

	import flash.utils.Dictionary;

	public class OpenRewardLevelCommand implements ICommand{

		/**
		 * если GameUser уже есть в кэше, значит мы уже получили список его ревардов с сервера
		 */
		private static var gameUserRewardsCache:Dictionary = new Dictionary();

		private var gameUser:GameUser;

		public function OpenRewardLevelCommand(gameUser:GameUser) {
			this.gameUser = gameUser;

			//  hook для того чтобы не загружать понялку воображаемого друга с сервера
			gameUserRewardsCache[ImaginaryGameUser.instance] = true;
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
				if(gameUserRewardsCache[gameUser])
					directlyStart();
				else
				{
					Config.application.showSlash(-1);
					AppServerHandler.instance.refreshUserInfo(gameUser, function(response:Object):void{
						Config.application.hideSplash();
						gameUserRewardsCache[gameUser] = true;
						directlyStart();
					},function(error:Object):void{
						Config.application.hideSplash();
						Config.application.message(Lang.t('UNDEFINED_SERVER_ERROR'));
					})
				}
			}
		}

		private function directlyStart():void
		{
			Config.application.startGame(new RewardLevelDef(gameUser));
		}
	}
}
