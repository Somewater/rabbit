package com.somewater.rabbit.application.tutorial {
	import com.somewater.rabbit.application.MainMenuPage;
	import com.somewater.rabbit.storage.Config;
	import com.somewater.rabbit.storage.LevelDef;
	import com.somewater.rabbit.storage.UserProfile;
	import com.somewater.storage.Lang;

	import flash.geom.Point;

	public class TutorialStep2 extends TutorialStepBase{

		private var messageShowed:Boolean = false;
		private var rabbitStartTile:Point;

		public function TutorialStep2() {
		}

		override public function tick():void {
			if(!TutorialManager.instance.levelStartWindowClosed) return;

			if(!messageShowed)
			{
				// "Используй кнопки-стрелки _L чтобы управлять кроликом"
				TutorialManager.instance.gameMessage('TUTORIAL_USE_CURSOR_KEYS', null, 'tutorial.TutorialCoursorKeys');
				messageShowed = true;
			}
		}

		override public function completed():Boolean
		{
			// проверить, что кролик сдвинулся
			var tile:Point = TutorialManager.modile.heroTile;
			if(tile && rabbitStartTile && (rabbitStartTile.x != tile.x || rabbitStartTile.y != tile.y))
				return true;

			if(tile)
				rabbitStartTile = tile.clone();

			return false;
		}
	}
}
