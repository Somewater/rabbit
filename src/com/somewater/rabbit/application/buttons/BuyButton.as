package com.somewater.rabbit.application.buttons {

	import com.somewater.rabbit.storage.Lib;
	import flash.display.Sprite;

	public class BuyButton extends GreenButton{
		protected var buyButtonMoneyIcon:Sprite

		public function BuyButton()
		{
			buyButtonMoneyIcon = Lib.createMC('interface.MoneyIcon');
			buyButtonMoneyIcon.y = 6;
			buyButtonMoneyIcon.scaleX = buyButtonMoneyIcon.scaleY = 0.7;
			buyButtonMoneyIcon.mouseEnabled = buyButtonMoneyIcon.mouseChildren = false;
			addChild(buyButtonMoneyIcon);
		}

		override protected function resize():void {
			super.resize();
			buyButtonMoneyIcon.x = this.textField.x + this.textField.width + 5;
		}
	}
}
