package com.somewater.rabbit.application
{
	import com.somewater.control.IClear;
	import com.somewater.display.HintedSprite;
	import com.somewater.rabbit.application.offers.OfferManager;
	import com.somewater.rabbit.storage.Config;
	import com.somewater.rabbit.storage.LevelDef;
	import com.somewater.rabbit.storage.LevelInstanceDef;
	import com.somewater.rabbit.storage.Lib;
	import com.somewater.rabbit.storage.UserProfile;
	import com.somewater.storage.Lang;
	import com.somewater.text.EmbededTextField;
	import com.somewater.text.Hint;

	import flash.display.DisplayObject;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.events.MouseEvent;
	import flash.text.TextField;

	public class LevelIcon extends HintedSprite implements IClear
	{
		private var hintHolder:Sprite;
		private var ground:DisplayObject;
		private var carrotsThree:Sprite;
		private var lockedGround:DisplayObject;
		private var levelTF:EmbededTextField;
		private var scoreTF:TextField;
		private var _data:LevelDef

		private var offerCounter:Sprite;
		private var offerCounterTF:EmbededTextField;
		
		public function LevelIcon()
		{
			hintHolder = new Sprite();
			addChild(hintHolder);

			ground = Lib.createMC("interface.LevelIcon");
			hintHolder.addChild(ground);

			carrotsThree = Lib.createMC("interface.CarrotsThree");
			carrotsThree.x = 17;
			carrotsThree.y = 51.5;
			hintHolder.addChild(carrotsThree);
			
			levelTF = new EmbededTextField(null, 0xFFFFFF, 18, true, false, false, false, "center");
			levelTF.x = 30;
			levelTF.y = 17;
			levelTF.width = 33;
			hintHolder.addChild(levelTF);
			
			scoreTF = new EmbededTextField(null, 0x124D18, 14, true);
			scoreTF.x = 54;
			scoreTF.y = 54;
			scoreTF.width = 33;
			hintHolder.addChild(scoreTF);
			
			lockedGround = Lib.createMC("interface.LockedLevelIcon");
			hintHolder.addChild(lockedGround);

			if(OfferManager.instance.active){
				offerCounter = Lib.createMC('interface.LevelIconOfferCounter');
				addChild(offerCounter);

				offerCounterTF = new EmbededTextField(Config.FONT_SECONDARY, 0xFFFFFF, 13, false, false, false, false, 'center');
				offerCounterTF.x = 11;
				offerCounterTF.y = 3;
				offerCounterTF.width = 20;
				offerCounter.addChild(offerCounterTF);
				(offerCounter.getChildByName('icon') as MovieClip).stop();
				offerCounter.x = 72;
				offerCounter.y = -3;
				offerCounter.scaleX = offerCounter.scaleY = 0.9;
			}
		}

		override protected function get hintArea():DisplayObject {
			return hintHolder;
		}

		public function clear():void
		{
			_data = null;
			hint = null;
			if(offerCounter)
				Hint.removeHint(offerCounter)
		}
		
		public function set data(value:LevelDef):void
		{
			_data = value;
			refresh();
		}
		
		public function get data():LevelDef
		{
			return _data;
		}
		
		private function refresh():void
		{
			var locked:Boolean = !UserProfile.instance.canPlayWithLevel(_data) && !Config.memory['portfolioMode'];
			var levelInstance:LevelInstanceDef = locked ? null : UserProfile.instance.getLevelInsanceByNumber(_data.number);
			lockedGround.visible = locked;
			levelTF.visible = scoreTF.visible = ground.visible = !locked;
			
			if(levelInstance != null)
			{
				levelTF.text = _data.number.toString();
				scoreTF.text = levelInstance.carrotHarvested.toString();
				hint = _data.name;
				stars = levelInstance.stars;
			}
			else if(!locked)
			{
				levelTF.text = _data.number.toString();
				scoreTF.text = "";//TODO запросить, сколько очков у юзера по тому или иному уровню
				hint = _data.name;
				stars = 0;
			}
			else
			{
				hint = Lang.t("ERROR_LOCKED_HINT");
				stars = 0;
			}

			if(offerCounter){
				var unharvested:Array = OfferManager.instance.levelOffers(_data.number, true);
				var offerType:int = OfferManager.instance.offerTypeByLevel(_data.number)
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
		}

		private function set stars(value:int):void
		{
			carrotsThree.getChildByName('c1').alpha = value > 0 ? 1 : 0.1;
			carrotsThree.getChildByName('c2').alpha = value > 1 ? 1 : 0.1;
			carrotsThree.getChildByName('c3').alpha = value > 2 ? 1 : 0.1;
		}
	}
}