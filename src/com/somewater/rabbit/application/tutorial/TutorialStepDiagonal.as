package com.somewater.rabbit.application.tutorial {
	import com.somewater.rabbit.storage.Config;

	import flash.utils.getTimer;

	public class TutorialStepDiagonal extends TutorialStepBase{

		private var messageShowed:Boolean = false;
		private var messageAccepted:Boolean = false;
		private var stepStartTime:uint;

		public function TutorialStepDiagonal() {
		}

		override public function tick():void {
			if(!TutorialManager.instance.levelStartWindowClosed) return;

			if(!messageShowed)
			{
				if(Config.application.mouseInput)
					TutorialManager.instance.gameMessage('TUTORIAL_MOUSE_CLICK_CARROT', onAccepted);
				else
					TutorialManager.instance.gameMessage('TUTORIAL_DIAGONAL_KEYS', onAccepted, 'tutorial.TutorialCoursorKeysDiagonal');
				stepStartTime = getTimer();
				messageShowed = true;
			}
		}

		private function onAccepted():void {
			messageAccepted = true;
		}

		override public function completed():Boolean
		{
			var diagonalMovement:Boolean = false;
			return messageShowed &&
					(messageAccepted ||
					(TutorialManager.USE_TIMEOUT && ((getTimer() - stepStartTime) > TutorialManager.TIME_WAITING * 1)) ||
					diagonalMovement);
		}
	}
}
