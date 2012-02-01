package com.somewater.rabbit.application.tutorial {
	import com.somewater.rabbit.application.MainMenuPage;
	import com.somewater.rabbit.storage.Config;
	import com.somewater.rabbit.storage.LevelDef;
	import com.somewater.rabbit.storage.UserProfile;
	import com.somewater.storage.Lang;

	import flash.geom.Point;

	public class TutorialStep3 extends TutorialStepBase{

		private var messageShowed:Boolean = false;
		private var rabbitStartTile:Point;

		public function TutorialStep3() {
		}

		override public function tick():void {
			if(!TutorialManager.instance.levelStartWindowClosed) return;

			if(!messageShowed)
			{
				// "Подведи кролика к морковкам, чтобы их собрать"
				TutorialManager.instance.gameMessage('TUTORIAL_MOVE_TO_CARROT', null);
				messageShowed = true;
			}
		}

		override public function completed():Boolean
		{
			// проверить, что кролик собрал 3 морковки
			return TutorialManager.modile.carrotHarvested > 3;
		}
	}
}
