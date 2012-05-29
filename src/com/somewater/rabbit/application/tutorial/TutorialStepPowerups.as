package com.somewater.rabbit.application.tutorial {

	import com.somewater.rabbit.application.GameGUI;
	import com.somewater.rabbit.application.shop.PowerupEvent;
	import com.somewater.rabbit.storage.Config;

	import flash.geom.Point;
	import flash.utils.getTimer;

	/**
	 * Заключительный шаг
	 */
	public class TutorialStepPowerups extends TutorialStepBase{
		private var messageShowed:Boolean = false;
		private var stepStartTime:uint;
		private var powerupEventListenerCreated:Boolean = false;
		private var powerupEvent:Boolean = false;


		public function TutorialStepPowerups() {
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
						TutorialManager.instance.highlightGui(gameGuiRef.powerupPanel.myPowerups.getPowerupIcon(TutorialManager.modile.health < 1 ? 0 : 1));
					}
					else
					{
						TutorialManager.instance.highlightGui(gameGuiRef.powerupIndicator);
						// проверить, что у юзера есть павеапы здоровья и ускорения, при необходимости выдать парочку
						gameGuiRef.powerupPanel.myPowerups.pushFreePowerup(0);
						gameGuiRef.powerupPanel.myPowerups.pushFreePowerup(1);
						gameGuiRef.powerupPanel.myPowerups.pushFreePowerup(2);
						gameGuiRef.powerupPanel.myPowerups.pushFreePowerup(3);
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
					((TutorialManager.USE_TIMEOUT && (getTimer() - stepStartTime) > TutorialManager.TIME_WAITING * 3) || powerupEvent);
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
