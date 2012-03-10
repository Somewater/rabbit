package com.somewater.rabbit.application.shop {
	import com.somewater.control.IClear;
	import com.somewater.rabbit.storage.Lib;
	import com.somewater.storage.Lang;
	import com.somewater.text.EmbededTextField;

	import flash.display.DisplayObject;

	import flash.display.Sprite;

	public class ShopModule extends Sprite implements IClear{

		public static const WIDTH:int = 640;
		public static const HEIGHT:int = 600;

		private const TOP_PANEL_Y:int = 40;
		private const CONTENT_HEIGHT:int = HEIGHT - 200;
		private const BOTTOM_PANEL_Y:int = HEIGHT - 100;


		private var myPowerups:MyPowerupsBag;
		private var myMoney:MyMoneyBag;

		public function ShopModule() {
			var title:EmbededTextField = new EmbededTextField(null, 0xDB661B, 20);
			title.text = Lang.t('SHOP').toUpperCase();
			title.x = (WIDTH - title.width) * 0.5;
			addChild(title);

			var myPowerupsGround:DisplayObject = Lib.createMC('interface.OpaqueBackground');
			myPowerupsGround.x = 0;
			myPowerupsGround.y = TOP_PANEL_Y;
			myPowerupsGround.width = 150;
			myPowerupsGround.height = MyPowerupsBag.HEIGHT;
			myPowerupsGround.width = MyPowerupsBag.MAX_WIDTH;
			addChild(myPowerupsGround);

			myPowerups = new MyPowerupsBag();
			myPowerups.x = 0;
			myPowerups.y = TOP_PANEL_Y;
			addChild(myPowerups);

			myMoney = new MyMoneyBag();
			myMoney.y = TOP_PANEL_Y;
			myMoney.x = WIDTH - MyMoneyBag.WIDTH;
			addChild(myMoney);

		}

		public function clear():void {
			myPowerups.clear();
			myMoney.clear();
		}
	}
}
