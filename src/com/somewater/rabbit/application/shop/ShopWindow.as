package com.somewater.rabbit.application.shop {
	import com.somewater.display.Window;
	import com.somewater.rabbit.storage.Config;

	public class ShopWindow extends Window{

		private var module:ShopModule;

		public function ShopWindow() {

			setSize(ShopModule.WIDTH, ShopModule.HEIGHT);

			module = new ShopModule();
			addChild(module)

			open();

			if(Config.gameModuleActive)
				Config.game.pause();
		}

		override public function clear():void {
			super.clear();
			module.clear();
			if(Config.gameModuleActive)
				Config.game.start();
		}
	}
}
