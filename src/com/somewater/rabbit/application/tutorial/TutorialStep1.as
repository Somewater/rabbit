package com.somewater.rabbit.application.tutorial {
	import com.somewater.rabbit.application.MainMenuPage;
	import com.somewater.rabbit.application.tutorial.TutorialManager;
	import com.somewater.rabbit.storage.Config;
	import com.somewater.rabbit.storage.LevelDef;
	import com.somewater.rabbit.storage.UserProfile;
	import com.somewater.storage.Lang;

	import flash.display.DisplayObject;

	public class TutorialStep1 extends TutorialStepBase{

		private var age:int = 0;

		public function TutorialStep1() {
		}

		override public function execute():void {
			TutorialManager.instance.guiMessage('TUTORIAL_I_AM_RABBIT', Config.WIDTH - 100, Config.HEIGHT - 100, onIAmRabbitAccepted, null, true);
			age = 0;

			if(TutorialManager.instance.mainMenuPage)
			{
				TutorialManager.instance.mainMenuPage.disableButtons();
				TutorialManager.instance.mainMenuPage.startGameButton.enabled = true;
			}
 		}


		override public function tick():void {
			age++;
			if(age == 10)// 2 секунда (200 мс х 10 = 2000)
			{
				// указать стрелкой на кнопку "Далее"
				try
				{
					var btnNext:DisplayObject = GuiCloud(TutorialManager.instance.messages[0]).cloud.buttonNext;
					var arrow:HighlightArrow = TutorialManager.instance.highlightGui(btnNext);
					arrow.rotation = -90;
					arrow.arrow.y -= btnNext.width * 0.5;
				}catch(err:Error){
					trace(err.getStackTrace());
				}
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
