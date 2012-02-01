package com.somewater.rabbit.application.tutorial {
	import com.somewater.controller.PopUpManager;
	import com.somewater.display.Window;
	import com.somewater.rabbit.application.GameGUI;
	import com.somewater.rabbit.application.MainMenuPage;
	import com.somewater.rabbit.application.windows.PauseMenuWindow;
	import com.somewater.rabbit.storage.Config;
	import com.somewater.rabbit.storage.LevelDef;
	import com.somewater.rabbit.storage.UserProfile;
	import com.somewater.storage.Lang;

	import flash.geom.Point;
	import flash.utils.getTimer;

	public class TutorialStep7 extends TutorialStepBase{

		private var messageShowed:Boolean = false;
		private var message2Showed:Boolean = false;
		private var messageAccepted:Boolean = false;
		private var message2Accepted:Boolean = false;
		private var stepStartTime:uint = 0;
		private var pauseWindowShowed:Boolean = false;

		public function TutorialStep7() {
		}

		override public function execute():void {
			super.execute();
		}

		override public function tick():void {
			if(!TutorialManager.instance.levelStartWindowClosed) return;

			var pauseWindow:PauseMenuWindow = this.pauseWindow;

			if(!messageShowed && pauseWindow == null)
			{
				TutorialManager.instance.gameMessage('TUTORIAL_PAUSE_HINT', onAccepted);
				var gameGuiRef:Object = Config.memory["GameGUI"];
				if(gameGuiRef)
					TutorialManager.instance.highlightGui(gameGuiRef['pauseButton']);
				messageShowed = true;
				stepStartTime = getTimer();
			}else if(messageShowed && !message2Showed && pauseWindow != null)
			{
				TutorialManager.instance.clearAllStuff();

				TutorialManager.instance.gameMessage('TUTORIAL_UN_PAUSE_HINT', onAccepted2);
				TutorialManager.instance.highlightGui(pauseWindow.closeButton);
				message2Showed = true;
				pauseWindowShowed = true;
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
			// окно паузы показалось и скрылось, либо прошло уже дофига времени
			return this.pauseWindow == null && (pauseWindowShowed || (getTimer() - stepStartTime) > TutorialManager.TIME_WAITING * 4);
		}

		private function get pauseWindow():PauseMenuWindow
		{
			var wnd:Window = PopUpManager.activeWindow;
			if(wnd)
				return wnd as PauseMenuWindow
			else
				return null;
		}
	}
}
