package com.somewater.rabbit.application.shop {
	import com.somewater.display.Window;
	import com.somewater.rabbit.storage.Config;
	import com.somewater.storage.Lang;

	import flash.display.DisplayObject;
	import flash.events.Event;

	public class ShopWindow extends Window{

		private var module:ShopModule;
		private var okButtonRef:DisplayObject;

		public function ShopWindow() {

			super(null, null, null, [Lang.t('SHOP_WINDOW_GOTO_GAME_BTN')]);

			const W_PADDING:int = 30;
			const H_PADDING:int = 10;
			setSize(ShopModule.WIDTH + W_PADDING * 2, ShopModule.HEIGHT + H_PADDING * 2);

			module = new ShopModule();
			module.basket.addEventListener(Event.CHANGE, onBasketChanged);
			module.x = W_PADDING;
			module.y = H_PADDING;
			addChild(module)

			open();

			okButtonRef = buttons[0];
			okButtonRef.y = this.height -okButtonRef.height - 10;
		}

		override public function clear():void {
			super.clear();
			module.clear();
			module.basket.removeEventListener(Event.CHANGE, onBasketChanged);
		}

		private function onBasketChanged(event:Event):void {
			okButtonRef.visible = !module.basket.visible;
		}
	}
}
