package com.somewater.rabbit.application.buttons {
	import com.somewater.rabbit.application.OrangeButton;
	import com.somewater.rabbit.storage.Lib;

	import flash.display.Sprite;

	public class GreenButton extends OrangeButton{
		public function GreenButton() {
		}

		override protected function createGround(type:String):Sprite {
			return Lib.createMC("interface.GreenButton_" + type);
		}
	}
}
