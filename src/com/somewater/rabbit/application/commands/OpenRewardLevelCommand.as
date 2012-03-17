package com.somewater.rabbit.application.commands {
	import com.somewater.rabbit.application.AppServerHandler;
	import com.somewater.rabbit.application.ImaginaryGameUser;
	import com.somewater.rabbit.application.ServerLogic;
	import com.somewater.rabbit.events.GameModuleEvent;
	import com.somewater.rabbit.storage.Config;
	import com.somewater.rabbit.storage.GameUser;
	import com.somewater.rabbit.storage.RewardInstanceDef;
	import com.somewater.rabbit.storage.RewardLevelDef;
	import com.somewater.rabbit.storage.UserProfile;
	import com.somewater.storage.Lang;

	import flash.events.Event;

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
				var userRewardsWithoutCurrent:Array;
				var positionRewards:Array = [];
				for each(var r:RewardInstanceDef in gameUser.rewards)
					if(r.x == 0 && r.y == 0)
					{
						userRewardsWithoutCurrent = gameUser.rewards.slice();
						if(userRewardsWithoutCurrent.indexOf(r) != -1)
							userRewardsWithoutCurrent.splice(userRewardsWithoutCurrent.indexOf(r),1)
						for(var i:int = 0;i<positionRewards.length;i++)
							if(userRewardsWithoutCurrent.indexOf(positionRewards[i]) == -1)
								userRewardsWithoutCurrent.push(positionRewards[i]);
						ServerLogic.positionReward(r, userRewardsWithoutCurrent);
						positionRewards.push(r);
					}
				if(positionRewards.length)
					AppServerHandler.instance.moveRewards(positionRewards);
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
			// если "созрела" награда за посещение, устанавливаем ее
			if(!gameUser.visitRewarded && gameUser.visitRewardTime < UserProfile.instance.serverUnixTime())
			{
				Config.application.addEventListener(GameModuleEvent.GAME_MODULE_STARTED_EVENT, createVisitRewardItem);
			}

			Config.application.startGame(new RewardLevelDef(gameUser));
		}

		/**
		 * Создать монетку
		 */
		private function createVisitRewardItem(event:Event):void
		{
			Config.application.removeEventListener(GameModuleEvent.GAME_MODULE_STARTED_EVENT, createVisitRewardItem);
			Config.game.createFriendVisitReward();
		}
	}
}
