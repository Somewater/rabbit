package com.somewater.rabbit.application.tutorial {
	import com.somewater.rabbit.application.RewardLevelGUI;
	import com.somewater.rabbit.storage.Config;
	import com.somewater.rabbit.storage.RewardLevelDef;
	import com.somewater.storage.Lang;

	import flash.utils.getTimer;

	public class TutorialStep9 extends TutorialStepBase{

		/**
		 * 1 - показано сообщение "вы прошли уровнень"
		 * 2 - показано сообщение "кликните на кнопку Награды"
		 * 3 - должно через 2 сек. быть показано сообщение "у кролика на полянке"
		 * 4 - показано сообщение "у кролика на полянке"
		 * 5 - показано сообщение "кликните на стрелку Назад"
		 */
		private var phase:int = 0;

		private var onAcceptedFlag:Boolean = false;
		private var startStepTime:uint;

		private var backArrowHighlighted:Boolean = false;

		public function TutorialStep9() {
		}

		override public function execute():void {
			phase = 0;
 		}

		override public function tick():void {
			if(phase == 0)
			{
				if(TutorialManager.instance.mainMenuPage != null)
				{
					startStepTime = getTimer();
					phase = 1;
					onAcceptedFlag = false;
					TutorialManager.instance.guiMessage('TUTORIAL_ON_LEVEL_COMPLETE', Config.WIDTH - 100, Config.HEIGHT - 100, onAccepted, null, true);

					TutorialManager.instance.mainMenuPage.disableButtons();
					TutorialManager.instance.mainMenuPage.rewardButton.enabled = true;
				}
			}
			else if(phase == 1)
			{
				if(onAcceptedFlag || (getTimer() - startStepTime) > TutorialManager.TIME_WAITING)
				{
					phase = 2;
					onAcceptedFlag = false;
					startStepTime = getTimer();
					TutorialManager.instance.guiMessage(Lang.t('TUTORIAL_REWARD_BUTTON', {button_label: Lang.t('MY_ACHIEVEMENTS')}),
							Config.WIDTH - 100, Config.HEIGHT - 100, onAccepted, null, true);
					if(TutorialManager.instance.mainMenuPage != null)
						TutorialManager.instance.highlightGui(TutorialManager.instance.mainMenuPage.rewardButton);
				}
			}

			if(!backArrowHighlighted && Config.gameModuleActive && Config.game.level && Config.game.level.type == RewardLevelDef.TYPE && RewardLevelDef(Config.game.level).gameUser.itsMe())
			{
				if(phase == 3)
				{
					if(getTimer() - startStepTime > 1500)
					{
						TutorialManager.instance.gameMessage('TUTORIAL_REWARD_PLACE_DESC', onAccepted);
						startStepTime = getTimer();
						onAcceptedFlag = false;
						phase = 4
					}
				}
				else if(phase == 4)
				{
					if(onAcceptedFlag || (getTimer() - startStepTime) > TutorialManager.TIME_WAITING)
					{
						TutorialManager.instance.gameMessage('TUTORIAL_CLICK_ON_BACK_ARROW_TO_MENU');
						var gameGuiRef:RewardLevelGUI = Config.application.gameGUI as RewardLevelGUI;
						if(gameGuiRef)
							TutorialManager.instance.highlightGui(gameGuiRef.backButton);
						backArrowHighlighted = true;
						onAcceptedFlag = false;
						phase = 5
					}
				}
				else if(phase <= 2)
				{
					TutorialManager.instance.clearAllStuff();

					phase = 3;
					onAcceptedFlag = false;

					// асинхронно стартуем сообщение, чтобы дать игроку 2 секунды чтобы насладиться картиной
					startStepTime = getTimer();
				}
			}
		}

		private function onAccepted():void {
			onAcceptedFlag = true;
		}

		override public function completed():Boolean
		{
			return phase > 2 && TutorialManager.instance.mainMenuPage != null;
		}
	}
}
