package com.somewater.rabbit.application.tutorial {
	import com.somewater.rabbit.application.LevelsPage;
	import com.somewater.rabbit.application.RewardLevelGUI;
	import com.somewater.rabbit.storage.Config;
	import com.somewater.rabbit.storage.RewardLevelDef;
	import com.somewater.storage.Lang;

	import flash.utils.getTimer;

	public class TutorialStep10 extends TutorialStepBase{

		/**
		 * 1 - "Нажми на кнопку LEVEL_SELECTION, чтобы увидеть уровни игры"
		 * 2 - "Все уровни разбиты на отдельные истории. Пройди уровни первой истории и получи доступ к уровням следующей" (2 секунды)
		 * 3 - "Нажми на стрелку, чтобы вернуться в главное меню"
		 */
		private var phase:int = 0;

		private var onAcceptedFlag:Boolean = false;
		private var startStepTime:uint;

		private var backArrowHighlighted:Boolean = false;

		public function TutorialStep10() {
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
					TutorialManager.instance.guiMessage(Lang.t('TUTORIAL_CLICK_TO_LEVELS_BTN', {button_label: Lang.t('LEVEL_SELECTION')}),
							Config.WIDTH - 100, Config.HEIGHT - 100, null, null, true);

					TutorialManager.instance.mainMenuPage.disableButtons();
					TutorialManager.instance.mainMenuPage.levelsButton.enabled = true;
					TutorialManager.instance.highlightGui(TutorialManager.instance.mainMenuPage.levelsButton);
				}
			}

			if(TutorialManager.instance.levelsPage != null)
			{
				if(phase < 2)
				{
					phase = 2;
					onAcceptedFlag = false;
					startStepTime = getTimer();
					TutorialManager.instance.guiMessage('TUTORIAL_LEVELS_DESC', Config.WIDTH - 100, Config.HEIGHT - 100, onAccepted, null, true);
				}
				else if(phase == 2)
				{
					if(onAcceptedFlag || (getTimer() - startStepTime) > TutorialManager.TIME_WAITING)
					{
						phase = 3;
						onAcceptedFlag = false;
						startStepTime = getTimer();
						TutorialManager.instance.guiMessage('TUTORIAL_CLICK_ON_BACK_ARROW_TO_MENU', Config.WIDTH - 100, Config.HEIGHT - 100, null, null, true);
						TutorialManager.instance.highlightGui(TutorialManager.instance.levelsPage.backButton);
					}
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
