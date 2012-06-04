package com.somewater.rabbit.application {
	import com.somewater.control.IClear;
	import com.somewater.rabbit.SoundTrack;
	import com.somewater.rabbit.Sounds;
	import com.somewater.rabbit.application.shop.MyMoneyBag;
	import com.somewater.rabbit.storage.Config;
	import com.somewater.rabbit.storage.LevelInstanceDef;
	import com.somewater.rabbit.storage.Lib;
	import com.somewater.storage.Lang;
	import com.somewater.text.Hint;

	import flash.display.DisplayObject;

	import flash.display.Sprite;
	import flash.events.MouseEvent;

	public class RewardLevelGUI extends Sprite implements IClear{

		private var leftButton:DisplayObject;
		private var offerStat:OfferStatPanel;
		private var myMoney:MyMoneyBag;

		public function RewardLevelGUI() {
			leftButton = Lib.createMC("interface.LeftButton");
			leftButton.x = 15;
			leftButton.y = Config.HEIGHT - leftButton.width - 15;
			leftButton.addEventListener(MouseEvent.CLICK, onLeftButtonClick);
			Hint.bind(leftButton, Lang.t("BACK_TO_MAIN_MENU"));
			addChild(leftButton);

			if(OfferManager.instance.quantity)
			{
				offerStat = new OfferStatPanel(OfferStatPanel.GAME_MODE);
				offerStat.x = Config.WIDTH - offerStat.width - 15;
				offerStat.y = 15;
				addChild(offerStat);
			}

			myMoney = new MyMoneyBag();
			myMoney.x = Config.WIDTH - (offerStat ? offerStat.width + 15 : 0) - MyMoneyBag.WIDTH - 15;
			myMoney.y = 15;
			addChild(myMoney);
		}

		public function clear():void
		{
			leftButton.removeEventListener(MouseEvent.CLICK, onLeftButtonClick);
			Hint.removeHint(leftButton);
			if(offerStat)
				offerStat.clear();
			myMoney.clear();
		}

		private function onLeftButtonClick(event:MouseEvent):void {
			Config.application.play(Sounds.ALPHA_BUTTON_CLICK, SoundTrack.INTERFACE, true);
			Config.game.finishLevel(LevelInstanceDef.DUMMY_FATAL_LEVEL);
			Config.application.startPage('main_menu');
		}

		// для тьюториала
		public function get backButton():DisplayObject
		{
			return leftButton;
		}
	}
}
