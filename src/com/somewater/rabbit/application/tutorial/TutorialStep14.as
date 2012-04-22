package com.somewater.rabbit.application.tutorial {

	import com.somewater.rabbit.application.GameGUI;
	import com.somewater.rabbit.application.shop.PowerupEvent;
	import com.somewater.rabbit.storage.Config;

	import flash.geom.Point;
	import flash.utils.getTimer;

	/**
	 * Заключительный шаг
	 */
	public class TutorialStep14 extends TutorialStepBase{
		private var messageShowed:Boolean = false;
		private var stepStartTime:uint;
		private var powerupEventListenerCreated:Boolean = false;
		private var powerupEvent:Boolean = false;


		public function TutorialStep14() {
		}

		override public function tick():void {
			if(!Config.gameModuleActive || !TutorialManager.instance.levelStartWindowClosed)
			{
				if(messageShowed)
				{
					TutorialManager.instance.clearAllStuff();
					messageShowed = false;
				}
				return;
			}


			if(messageShowed)
			{
				var gameGuiRef:GameGUI = Config.application.gameGUI as GameGUI;
				if(gameGuiRef)
				{
					// подсветить какой-нибудь не закончившийся паверап
					if(gameGuiRef.powerupPanel.isOpened())
					{
						TutorialManager.instance.clearMessages();
						TutorialManager.instance.highlightGui(gameGuiRef.powerupPanel.myPowerups.getPowerupIcon());
					}
					else
					{
						TutorialManager.instance.highlightGui(gameGuiRef.powerupIndicator);
					}
					if(!powerupEventListenerCreated)
					{
						gameGuiRef.powerupPanel.myPowerups.addEventListener(PowerupEvent.POWERUP_EVENT, onPowerupEvent, false, 0, true);
						powerupEventListenerCreated = true;
					}
				}
			}
			else
			{
				TutorialManager.instance.gameMessage('TUTORIAL_POWERUPS_MSG');
				stepStartTime = getTimer();
				messageShowed = true;
			}
		}

		override public function completed():Boolean
		{
			// прошло 5 или была нажата кнопка Accept
			return messageShowed &&
					((getTimer() - stepStartTime) > TutorialManager.TIME_WAITING * 3 || powerupEvent);
		}

		override public function clear():void {
			super.clear();
			if(powerupEventListenerCreated)
			{
				var gameGuiRef:GameGUI = Config.application.gameGUI as GameGUI;
				if(gameGuiRef)
					gameGuiRef.powerupPanel.myPowerups.removeEventListener(PowerupEvent.POWERUP_EVENT, onPowerupEvent);
			}
		}

		private function onPowerupEvent(event:PowerupEvent):void {
			powerupEvent = true;
		}
	}
}
