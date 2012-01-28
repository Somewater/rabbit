package com.somewater.rabbit.application.commands {
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
