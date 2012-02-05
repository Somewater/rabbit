package com.somewater.rabbit.application.tutorial {
	import com.somewater.rabbit.application.ImaginaryGameUser;
	import com.somewater.rabbit.application.LevelsPage;
	import com.somewater.rabbit.application.RewardLevelGUI;
	import com.somewater.rabbit.storage.Config;
	import com.somewater.rabbit.storage.RewardLevelDef;
	import com.somewater.storage.Lang;

	import flash.utils.getTimer;

	public class TutorialStep11 extends TutorialStepBase{

		/**
		 * Посмтреть на полянку друга (можно воображаемого)
		 * 1 - "Нажми на портрет друга, чтобы посмотреть на его полянку с наградами"
	 	 * 2 - "Каждый день заходя к другу, ты можешь собрать 1 морковку"
	 	 * 3 - "Нажми на стрелку, чтобы вернуться в главное меню"
		 */
		private var phase:int = 0;

		private var onAcceptedFlag:Boolean = false;
		private var startStepTime:uint;

		public function TutorialStep11() {
		}

		override public function execute():void {
			phase = 0;
 		}

		override public function tick():void {
			if(phase == 0)
			{
				if(TutorialManager.instance.mainMenuPage != null)
				{
					phase = 1;
					TutorialManager.instance.guiMessage(Lang.t('TUTORIAL_CLICK_ON_FRIEND'), Config.WIDTH - 100, Config.HEIGHT - 100, null, null, true);
				}
			}else if(phase == 1 && TutorialManager.instance.mainMenuPage != null)
			{
				// каждый тик выделяем иконку заново, т.к. она может переместиться под действием стрелочек
				TutorialManager.instance.highlightGui(TutorialManager.instance.mainMenuPage.getFriendBar().getImaginaryFriendIcon());
			}

			if(Config.gameModuleActive && Config.game.level && Config.game.level.type == RewardLevelDef.TYPE && RewardLevelDef(Config.game.level).gameUser is ImaginaryGameUser)
			{
				if(phase == 2)
				{
					if(getTimer() - startStepTime > 1500)
					{
						phase = 3;
						onAcceptedFlag = false;
						startStepTime = getTimer();
						TutorialManager.instance.gameMessage('TUTORIAL_FRIEND_BONUS_DESC', onAccepted);
					}
				}
				else if(phase == 3)
				{
					if(onAcceptedFlag || (getTimer() - startStepTime) > TutorialManager.TIME_WAITING)
					{
						phase = 4;
						onAcceptedFlag = false;
						startStepTime = getTimer();
						TutorialManager.instance.gameMessage('TUTORIAL_CLICK_ON_BACK_ARROW_TO_MENU');
						var gameGuiRef:RewardLevelGUI = Config.application.gameGUI as RewardLevelGUI;
						if(gameGuiRef)
							TutorialManager.instance.highlightGui(gameGuiRef.backButton);
					}
				}else if(phase < 2)
				{
					phase = 2;
					onAcceptedFlag = false;
					startStepTime = getTimer();
				}
			}
		}

		private function onAccepted():void {
			onAcceptedFlag = true;
		}

		override public function completed():Boolean
		{
			return phase > 1 && TutorialManager.instance.mainMenuPage != null;
		}
	}
}
