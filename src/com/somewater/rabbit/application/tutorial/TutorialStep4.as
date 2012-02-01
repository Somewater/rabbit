package com.somewater.rabbit.application.tutorial {
	import com.somewater.rabbit.application.GameGUI;
	import com.somewater.rabbit.application.MainMenuPage;
	import com.somewater.rabbit.storage.Config;
	import com.somewater.rabbit.storage.LevelDef;
	import com.somewater.rabbit.storage.UserProfile;
	import com.somewater.storage.Lang;

	import flash.geom.Point;
	import flash.utils.getTimer;

	public class TutorialStep4 extends TutorialStepBase{

		private var messageShowed:Boolean = false;
		private var messageAccepted:Boolean = false;
		private var stepStartTime:uint;

		public function TutorialStep4() {
		}

		override public function tick():void {
			if(!TutorialManager.instance.levelStartWindowClosed) return;

			if(!messageShowed)
			{
				// "Индикатор морковок показывает, сколько морковок еще не собрано"
				TutorialManager.instance.gameMessage('TUTORIAL_CARROT_INDICATOR_HINT', onAccepted);
				var gameGuiRef:Object = Config.memory["GameGUI"];
				if(gameGuiRef)
					TutorialManager.instance.highlightGui(gameGuiRef['carrotIndicator']);
				stepStartTime = getTimer();
				messageShowed = true;
			}
		}

		private function onAccepted():void {
			messageAccepted = true;
		}

		override public function completed():Boolean
		{
			// прошло 5 секунды или здоровье кролика менее 1
			// (значит, он столкнулся с ежом, надо переходить к следующему шагу - про ежа)
			return messageShowed &&
					(messageAccepted || (getTimer() - stepStartTime) > TutorialManager.TIME_WAITING || TutorialManager.modile.health < 1);
		}
	}
}
