package com.somewater.rabbit.social {
	import com.somewater.rabbit.storage.Config;
	import com.somewater.rabbit.storage.LevelDef;
	import com.somewater.rabbit.storage.UserProfile;

	public class StartNextLevelCommand implements ICommand{

		private var currentPassedLevel:LevelDef;

		public function StartNextLevelCommand(currentPassedLevel:LevelDef) {
			this.currentPassedLevel = currentPassedLevel;
		}

		public function execute():void {
			// стартуем следующий непройденный уровень, если мы только что прошли новый (ранее непройденный) уровень
			if(UserProfile.instance.levelNumber - 1 == currentPassedLevel.number
					&& Config.application.getLevelByNumber(UserProfile.instance.levelNumber) != null)  // и еще есть непройденные уровни
				Config.application.startGame();
			// иначе переходим в меню уровней
			else
				Config.application.startPage('levels');
		}
	}
}
