package com.somewater.rabbit.application.tutorial {
	import com.somewater.rabbit.application.MainMenuPage;
	import com.somewater.rabbit.application.tutorial.TutorialManager;
	import com.somewater.rabbit.storage.Config;
	import com.somewater.rabbit.storage.LevelDef;
	import com.somewater.rabbit.storage.UserProfile;
	import com.somewater.storage.Lang;

	public class TutorialStep1 extends TutorialStepBase{

		public function TutorialStep1() {
		}

		override public function execute():void {
			TutorialManager.instance.guiMessage('TUTORIAL_I_AM_RABBIT', Config.WIDTH - 100, Config.HEIGHT - 100, onIAmRabbitAccepted, null, true);

			if(TutorialManager.instance.mainMenuPage)
			{
				TutorialManager.instance.mainMenuPage.disableButtons();
				TutorialManager.instance.mainMenuPage.startGameButton.enabled = true;
			}
 		}

		private function onIAmRabbitAccepted():void {
			TutorialManager.instance.clearMessages();

			TutorialManager.instance.guiMessage(
				Lang.t('TUTORIAL_CLICK_ON_START_BTN', {'button_label': UserProfile.instance.levelNumber == 1 ? Lang.t('START_GAME') : Lang.t('CONTINUE_GAME')}),
				Config.WIDTH - 100, Config.HEIGHT - 100, null, null,true);

			TutorialManager.instance.highlightGui(TutorialManager.instance.mainMenuPage.startGameButton);
		}

		override public function completed():Boolean
		{
			// велючили один из уровней игры
			return Config.gameModuleActive && Config.game.level && Config.game.level.type == LevelDef.TYPE;
		}

		override public function clear():void {
			if(TutorialManager.instance.mainMenuPage)
				TutorialManager.instance.mainMenuPage.disableButtons(false);
		}
	}
}
