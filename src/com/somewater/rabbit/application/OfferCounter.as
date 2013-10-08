package com.somewater.rabbit.application {
	import com.somewater.control.IClear;
	import com.somewater.rabbit.application.offers.OfferManager;
	import com.somewater.rabbit.storage.Config;
	import com.somewater.rabbit.storage.Lib;
	import com.somewater.storage.Lang;
	import com.somewater.text.EmbededTextField;
	import com.somewater.text.Hint;

	import flash.display.MovieClip;

	import flash.display.Sprite;

	public class OfferCounter extends Sprite implements IClear{
		private var offerCounter:Sprite;
		private var offerCounterTF:EmbededTextField;

		public function OfferCounter() {
			offerCounter = Lib.createMC('interface.LevelIconOfferCounter');
			addChild(offerCounter);

			offerCounterTF = new EmbededTextField(Config.FONT_SECONDARY, 0xFFFFFF, 13, false, false, false, false, 'center');
			offerCounterTF.x = 11;
			offerCounterTF.y = 3;
			offerCounterTF.width = 20;
			offerCounter.addChild(offerCounterTF);
			(offerCounter.getChildByName('icon') as MovieClip).stop();
			offerCounter.scaleX = offerCounter.scaleY = 0.9;


		}

		public function set levelNum(value:int):void {
			var unharvested:Array = OfferManager.instance.levelOffers(value, true);
			var offerType:int = OfferManager.instance.offerTypeByLevel(value)
			if(unharvested.length){
				offerCounter.visible = true;
				offerCounterTF.text = unharvested.length.toString();
				(offerCounter.getChildByName('icon') as MovieClip).gotoAndStop(offerType + 1)
				var offerHint = Lang.t("OFFERS_HINT_LVL_" + offerType, {n: unharvested.length});
				Hint.bind(offerCounter, offerHint)
			} else {
				offerCounter.visible = false;
			}
		}

		public function clear():void {
			Hint.removeHint(offerCounter)
		}
	}
}
