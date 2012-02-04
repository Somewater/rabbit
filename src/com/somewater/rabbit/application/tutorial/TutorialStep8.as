package com.somewater.rabbit.application.tutorial {
	import flash.utils.getTimer;

	public class TutorialStep8 extends TutorialStepBase{

		private var messageShowed:Boolean = false;
		private var messageAccepted:Boolean = false;
		private var stepStartTime:uint;

		public function TutorialStep8() {
		}

		override public function tick():void {
			if(!TutorialManager.instance.levelStartWindowClosed) return;

			if(!messageShowed)
			{
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
					(messageAccepted || (getTimer() - stepStartTime) > TutorialManager.TIME_WAITING * 3 || diagonalMovement);
		}
	}
}
