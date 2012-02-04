package com.somewater.rabbit.application.tutorial {
	import com.somewater.rabbit.application.GameGUI;
	import com.somewater.rabbit.application.MainMenuPage;
	import com.somewater.rabbit.storage.Config;
	import com.somewater.rabbit.storage.LevelDef;
	import com.somewater.rabbit.storage.UserProfile;
	import com.somewater.storage.Lang;

	import flash.geom.Point;
	import flash.utils.getTimer;

	public class TutorialStep5 extends TutorialStepBase{

		private var messageShowed:Boolean = false;
		private var message2Showed:Boolean = false;
		private var messageAccepted:Boolean = false;
		private var message2Accepted:Boolean = false;
		private var stepStartTime:uint;
		private var startRabbitHealth:Number;

		public function TutorialStep5() {
		}

		override public function execute():void {
			super.execute();
		}

		override public function tick():void {
			if(!TutorialManager.instance.levelStartWindowClosed) return;

			if(!messageShowed)
			{
				TutorialManager.instance.gameMessage('TUTORIAL_HEDGEHOG_ATTENTION', onAccepted);
				// todo: выделить ежика
				startRabbitHealth = TutorialManager.modile.health;
				stepStartTime = getTimer();
				messageShowed = true;
			}else if(messageShowed && !message2Showed &&
					// кролика уколол ежик или прошло 5 секунды
					(messageAccepted || TutorialManager.modile.health < startRabbitHealth || (stepStartTime - getTimer()) > TutorialManager.TIME_WAITING))
			{
				TutorialManager.instance.gameMessage('TUTORIAL_HEALTH_INDICATOR_HINT', onAccepted2);
				var gameGuiRef:GameGUI = Config.application.gameGUI as GameGUI;
				if(gameGuiRef)
					TutorialManager.instance.highlightGui(gameGuiRef.healthIndicator);
				stepStartTime = getTimer();
				message2Showed = true;
			}
		}

		private function onAccepted():void {
			messageAccepted = true;
		}

		private function onAccepted2():void {
			message2Accepted = true;
		}

		override public function completed():Boolean
		{
			// прошло 5 секунды
			return messageShowed && message2Showed &&
					(message2Accepted || (getTimer() - stepStartTime) > TutorialManager.TIME_WAITING);
		}
	}
}
