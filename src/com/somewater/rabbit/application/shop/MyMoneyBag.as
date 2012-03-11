package com.somewater.rabbit.application.shop {
	import com.somewater.control.IClear;
	import com.somewater.rabbit.storage.Config;
	import com.somewater.rabbit.storage.Lib;
	import com.somewater.rabbit.storage.UserProfile;
	import com.somewater.storage.Lang;
	import com.somewater.text.EmbededTextField;
	import com.somewater.text.Hint;

	import flash.display.DisplayObject;
	import flash.display.SimpleButton;

	import flash.display.Sprite;
	import flash.events.MouseEvent;

	/**
	 * Панель, показывающая деньги игрока, кнопкку поплнения баланса
	 */
	public class MyMoneyBag extends Sprite implements IClear{

		public static const WIDTH:int = 140;
		public static const HEIGHT:int = 48;

		private var quantityTF:EmbededTextField;
		private var plus:SimpleButton;
		private var ground:DisplayObject

		public function MyMoneyBag() {

			ground = Lib.createMC('interface.OpaqueBackground');
			ground.width = WIDTH;
			ground.height = HEIGHT;
			addChild(ground);
			Hint.bind(ground, hintMoney);

			var icon:DisplayObject = Lib.createMC('interface.MoneyIcon');
			icon.scaleX = icon.scaleY = 38/icon.height;
			icon.x = 5;
			icon.y = (HEIGHT - icon.height) * 0.5;
			addChild(icon);

			quantityTF = new EmbededTextField(Config.FONT_SECONDARY, 0xFFFFFF, 25, true);
			quantityTF.x = icon.x + icon.width + 5;
			quantityTF.y = 7;
			addChild(quantityTF);

			plus = Lib.createMC('interface.GreenPlus');
			plus.x = WIDTH - plus.width - 5;
			plus.y = (HEIGHT - plus.height) * 0.5;
			addChild(plus);
			plus.addEventListener(MouseEvent.CLICK, onPlusClicked);
			Hint.bind(plus, Lang.t('SHOP_ADD_MONEY_HINT'))

			UserProfile.bind(onUserDataChanged)
		}

		private function onUserDataChanged():void {
			quantityTF.text = UserProfile.instance.money.toString();
		}

		public function clear():void {
			plus.removeEventListener(MouseEvent.CLICK, onPlusClicked);
			UserProfile.unbind(onUserDataChanged);
			Hint.removeHint(ground);
			Hint.removeHint(plus);
		}

		private function hintMoney():String{
			return Lang.t('SHOP_MONEY_PANEL_HINT', {quantity: UserProfile.instance.money})
		}

		private function onPlusClicked(event:MouseEvent):void {
			new BuyMoneyWindow();
		}
	}
}
