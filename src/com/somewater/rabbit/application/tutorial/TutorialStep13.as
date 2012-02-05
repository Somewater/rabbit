package com.somewater.rabbit.application.tutorial {
	import com.somewater.rabbit.application.LevelsPage;
	import com.somewater.rabbit.application.RewardLevelGUI;
	import com.somewater.rabbit.storage.Config;
	import com.somewater.rabbit.storage.RewardLevelDef;
	import com.somewater.storage.Lang;

	import flash.utils.getTimer;

	/**
	 * Заключительный шаг
	 */
	public class TutorialStep13 extends TutorialStepBase{

		private var onAcceptedFlag:Boolean = false;
		private var startStepTime:uint = 0;
		private var someLevelStarted:Boolean = false;
		private var messaggeShoved:Boolean = false;

		public function TutorialStep13() {
		}

		override public function tick():void {
			if(messaggeShoved)
			{
				if(TutorialManager.instance.mainMenuPage == null)
					someLevelStarted = true;
			}
			else
			{
				if(TutorialManager.instance.mainMenuPage != null)
				{
					startStepTime = getTimer();
					TutorialManager.instance.guiMessage('TUTORIAL_TITRE', Config.WIDTH - 100, Config.HEIGHT - 100, onAccepted, null, true);
					TutorialManager.instance.highlightGui(TutorialManager.instance.mainMenuPage.startGameButton);
					messaggeShoved = true;
				}
			}
		}

		private function onAccepted():void {
			onAcceptedFlag = true;
		}

		override public function completed():Boolean
		{
			return someLevelStarted || onAcceptedFlag || (getTimer() - startStepTime) > TutorialManager.TIME_WAITING;
		}
	}
}
