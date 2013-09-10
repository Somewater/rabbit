package com.somewater.rabbit.application {
	import com.somewater.rabbit.storage.Config;
	import com.somewater.rabbit.storage.Lib;
	import com.somewater.text.EmbededTextField;

	import flash.display.DisplayObject;

	import flash.display.Sprite;

	public class NumberIndicator extends Sprite{

		private var _number:int;
		public var textField:EmbededTextField;
		private var back:DisplayObject;

		public function NumberIndicator() {
			back = Lib.createMC('interface.NumberIndicator');
			addChild(back);

			textField = new EmbededTextField(null, 0xFFFFFF, 12, false, false, false, false, 'center');
			textField.x = 3.5;
			textField.y = 3;
			textField.width = 18;
			addChild(textField);

			number = 0;
		}

		public function get number():int {
			return _number;
		}

		public function set number(value:int):void {
			_number = value;
			textField.text = value.toString();
		}
	}
}
