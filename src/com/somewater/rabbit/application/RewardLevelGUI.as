package com.somewater.rabbit.application {
	import com.somewater.control.IClear;
	import com.somewater.rabbit.SoundTrack;
	import com.somewater.rabbit.Sounds;
	import com.somewater.rabbit.application.buttons.InteractiveOpaqueBack;
	import com.somewater.rabbit.application.offers.OfferManager;
	import com.somewater.rabbit.application.offers.OfferStatPanel;
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

		private var leftButton:InteractiveOpaqueBack;
		private var offerStats:Array = [];
		private var myMoney:MyMoneyBag;

		public function RewardLevelGUI() {
			leftButton = new InteractiveOpaqueBack(Lib.createMC("interface.LeftButton"));
			leftButton.x = 15;
			leftButton.y = Config.HEIGHT - leftButton.width - 15;
			leftButton.setSize(48, 48)
			leftButton.addEventListener(MouseEvent.CLICK, onLeftButtonClick);
			Hint.bind(leftButton, Lang.t("BACK_TO_MAIN_MENU"));
			addChild(leftButton);

			if(OfferManager.instance.active)
			{
				for each(var offerType:int in OfferManager.instance.types){
					var offerStat:OfferStatPanel = new OfferStatPanel(OfferStatPanel.GAME_MODE, offerType);
					offerStat.x = Config.WIDTH - offerStat.width - 15;
					offerStat.y = 15 + offerType * 50;
					addChild(offerStat);
					offerStats.push(offerStat);
				}
			}

			myMoney = new MyMoneyBag();
			myMoney.x = Config.WIDTH - (offerStats.length ? (offerStats[offerStats.length - 1] as OfferStatPanel).width + 15 : 0) - MyMoneyBag.WIDTH - 15;
			myMoney.y = 15;
			addChild(myMoney);
		}

		public function clear():void
		{
			leftButton.removeEventListener(MouseEvent.CLICK, onLeftButtonClick);
			leftButton.clear();
			Hint.removeHint(leftButton);
			for each(var of:OfferStatPanel in offerStats)
				of.clear();
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
