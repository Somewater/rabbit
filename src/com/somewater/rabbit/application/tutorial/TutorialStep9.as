package com.somewater.rabbit.application.tutorial {
	import com.somewater.rabbit.storage.Config;
	import flash.utils.getTimer;

	public class TutorialStep9 extends TutorialStepBase{

		private var onAcceptedFlag:Boolean = false;
		private var startStepTime:uint;

		public function TutorialStep9() {
		}

		override public function execute():void {
			TutorialManager.instance.guiMessage('TUTORIAL_ON_LEVEL_COMPLETE', Config.WIDTH - 100, Config.HEIGHT - 100, onAccepted, null, true);
 		}

		private function onAccepted():void {
			onAcceptedFlag = true;
		}

		override public function completed():Boolean
		{
			return onAcceptedFlag || (getTimer() - startStepTime) > TutorialManager.TIME_WAITING;
		}
	}
}
