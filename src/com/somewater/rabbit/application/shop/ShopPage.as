package com.somewater.rabbit.application.shop {
	import com.somewater.rabbit.SoundTrack;
	import com.somewater.rabbit.Sounds;
	import com.somewater.rabbit.application.PageBase;
	import com.somewater.rabbit.storage.Config;
	import com.somewater.rabbit.storage.Lib;
	import com.somewater.storage.Lang;
	import com.somewater.text.Hint;

	import flash.display.DisplayObject;
	import flash.events.MouseEvent;

	public class ShopPage extends PageBase{

		private var module:ShopModule;
		private var leftButton:DisplayObject;

		public function ShopPage() {
			super();
			logo.visible = false;

			module = new ShopModule()
			module.x = (Config.WIDTH - ShopModule.WIDTH) * 0.5;
			module.y = (Config.HEIGHT - ShopModule.HEIGHT) * 0.5;
			addChild(module);

			leftButton = Lib.createMC("interface.LeftButton");
			leftButton.x = 20;
			leftButton.y = Config.HEIGHT - leftButton.height - 20;
			leftButton.addEventListener(MouseEvent.CLICK, onLeftButtonClick);
			Hint.bind(leftButton, Lang.t("BACK_TO_MAIN_MENU"));
			addChild(leftButton);
		}

		override public function clear():void {
			super.clear();
			module.clear();
			leftButton.removeEventListener(MouseEvent.CLICK, onLeftButtonClick);
		}

		private function onLeftButtonClick(event:MouseEvent):void {
			Config.application.play(Sounds.ALPHA_BUTTON_CLICK, SoundTrack.INTERFACE, true);
			Config.application.startPage("main_menu");
		}
	}
}
