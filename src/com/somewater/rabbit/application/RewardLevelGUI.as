package com.somewater.rabbit.application {
	import com.somewater.control.IClear;
	import com.somewater.rabbit.SoundTrack;
	import com.somewater.rabbit.Sounds;
	import com.somewater.rabbit.storage.Config;
	import com.somewater.rabbit.storage.Lib;
	import com.somewater.storage.Lang;
	import com.somewater.text.Hint;

	import flash.display.DisplayObject;

	import flash.display.Sprite;
	import flash.events.MouseEvent;

	public class RewardLevelGUI extends Sprite implements IClear{

		private var leftButton:DisplayObject;

		public function RewardLevelGUI() {
			leftButton = Lib.createMC("interface.LeftButton");
			leftButton.x = 15;
			leftButton.y = Config.HEIGHT - leftButton.width - 15;
			leftButton.addEventListener(MouseEvent.CLICK, onLeftButtonClick);
			Hint.bind(leftButton, Lang.t("BACK_TO_MAIN_MENU"));
			addChild(leftButton);
		}

		public function clear():void
		{
			leftButton.removeEventListener(MouseEvent.CLICK, onLeftButtonClick);
			Hint.removeHint(leftButton);
		}

		private function onLeftButtonClick(event:MouseEvent):void {
			Config.application.play(Sounds.ALPHA_BUTTON_CLICK, SoundTrack.INTERFACE, true);
			Config.application.startPage('main_menu');
		}

		// для тьюториала
		public function get backButton():DisplayObject
		{
			return leftButton;
		}
	}
}
