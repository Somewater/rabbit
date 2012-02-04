package com.somewater.rabbit.application.commands {
	import com.somewater.rabbit.application.tutorial.TutorialManager;
	import com.somewater.rabbit.storage.Config;
	import com.somewater.rabbit.storage.LevelDef;
	import com.somewater.rabbit.storage.UserProfile;

	public class StartNextLevelCommand implements ICommand{

		private var currentPassedLevel:LevelDef;

		public function StartNextLevelCommand(currentPassedLevel:LevelDef = null) {
			this.currentPassedLevel = currentPassedLevel;
		}

		public function execute():void {

			var nextLevelDef:LevelDef = Config.application.getLevelByNumber(UserProfile.instance.levelNumber);

			// хук для тьюториала. Если тольтко что пройден первый левел игры, тьюториал не доведен до (LEVEL_LAST_STEP+1) шага
			// и стартовать пытается 2й левел, открываем главное меню
			if(currentPassedLevel && currentPassedLevel.number == 1 &&
					TutorialManager.instance.stepIndex() != -1 && TutorialManager.instance.stepIndex() <= TutorialManager.LEVEL_LAST_STEP)
			{
				Config.application.startPage('main_menu');
				return;
			}

			// стартуем следующий непройденный уровень, если мы только что прошли новый (ранее непройденный) уровень,
			// либо если только что пройденый уровень не задан (старт из главного меню по кнопке "Продолжить игру")
			if((currentPassedLevel == null || UserProfile.instance.levelNumber - 1 == currentPassedLevel.number)
					&& nextLevelDef != null // и еще есть непройденные уровни
					&& nextLevelDef.story && nextLevelDef.story.enabled) // уровень относится к активированной истории
				Config.application.startGame(Config.application.getLevelByNumber(UserProfile.instance.levelNumber));
			// иначе переходим в меню уровней
			else
				Config.application.startPage('levels');
		}
	}
}
