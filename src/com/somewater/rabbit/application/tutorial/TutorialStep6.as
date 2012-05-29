package com.somewater.rabbit.application.tutorial {
	import com.somewater.rabbit.application.GameGUI;
	import com.somewater.rabbit.application.MainMenuPage;
	import com.somewater.rabbit.storage.Config;
	import com.somewater.rabbit.storage.LevelDef;
	import com.somewater.rabbit.storage.UserProfile;
	import com.somewater.storage.Lang;

	import flash.geom.Point;
	import flash.utils.getTimer;

	public class TutorialStep6 extends TutorialStepBase{

		private var messageShowed:Boolean = false;
		private var messageAccepted:Boolean = false;
		private var stepStartTime:uint;

		public function TutorialStep6() {
		}

		override public function tick():void {
			if(!TutorialManager.instance.levelStartWindowClosed) return;

			if(!messageShowed)
			{
				TutorialManager.instance.gameMessage('TUTORIAL_TIME_COUNTER_HINT', onAccepted);
				var gameGuiRef:GameGUI = Config.application.gameGUI as GameGUI;
				if(gameGuiRef)
					TutorialManager.instance.highlightGui(gameGuiRef.timeIndicator);
				stepStartTime = getTimer();
				messageShowed = true;
			}
		}

		private function onAccepted():void {
			messageAccepted = true;
		}

		override public function completed():Boolean
		{
			// прошло 8 секунды
			return messageShowed &&
					(messageAccepted || (TutorialManager.USE_TIMEOUT && (getTimer() - stepStartTime) > TutorialManager.TIME_WAITING));
		}
	}
}
