package com.somewater.rabbit.application.map {
	import com.somewater.control.IClear;
	import com.somewater.display.HintedSprite;
	import com.somewater.rabbit.application.OfferCounter;
	import com.somewater.rabbit.application.offers.OfferManager;
	import com.somewater.rabbit.storage.Config;
	import com.somewater.rabbit.storage.LevelDef;
	import com.somewater.rabbit.storage.LevelInstanceDef;
	import com.somewater.rabbit.storage.Lib;
	import com.somewater.rabbit.storage.UserProfile;
	import com.somewater.storage.Lang;
	import com.somewater.text.EmbededTextField;

	import flash.display.MovieClip;

	import flash.display.Sprite;
	import flash.filters.DropShadowFilter;

	public class MapLevelIcon extends HintedSprite implements IClear{

		private static const offerPosExceptions:Object = {
			6: [-20, -6],
			20: [-20, -6],
			21: [-20, -6],
			23: [-20, -6]
		}

		protected var core:MovieClip;
		protected var levelTextField:EmbededTextField;
		public var levelNum:int;
		public var levelInstance:LevelInstanceDef;
		public var active:Boolean;
		private var offerCounter:OfferCounter;

		public function MapLevelIcon() {
			core = Lib.createMC('interface.MapLevelCore');
			addChild(core);

			levelTextField = new EmbededTextField(null, 0xFFFFFF, 30, false, false, false, false, 'center');
			levelTextField.y = 8;
			levelTextField.width = 63;
			levelTextField.height = 40;
			addChild(levelTextField);

			filters = [new DropShadowFilter(2, 45, 0, 0.5, 10, 10)];
		}

		public function clear():void {
			if(offerCounter)
				offerCounter.clear();
			hint = null;
		}

		public function refresh():void {
			core.lock.visible = false;
			core.ground.visible = false;
			core.carrot1.visible = false;
			core.carrot2.visible = false;
			core.carrot3.visible = false;
			active = false;

			if(levelInstance){
				core.ground.visible = true;
				for(var i:int = 1;i<=3; i++){
					core['carrot' + i].visible = levelInstance.stars >= i;
					(core['carrot' + i] as Sprite).mouseEnabled = false;
					(core['carrot' + i] as Sprite).mouseChildren = false;
				}
				active = true;
			} else if(Config.application.getLevelByNumber(levelNum) &&
					(Config.memory['portfolioMode'] || levelNum <= UserProfile.instance.levelNumber)){
				core.ground.visible = true;
				active = true;
			} else {
				core.lock.visible = true;
				active = false;
				hint = Lang.t("ERROR_LOCKED_HINT");
			}
			buttonMode = useHandCursor = active;
			levelTextField.visible = active;
			if(active){
				levelTextField.text = levelNum.toString();
				hint = Config.application.getLevelByNumber(levelNum).name;
			}

			if(OfferManager.instance.active){
				offerCounter = new OfferCounter();
				offerCounter.x = offerPosExceptions[levelNum] ? offerPosExceptions[levelNum][0] : 45;
				offerCounter.y = offerPosExceptions[levelNum] ? offerPosExceptions[levelNum][1] : -6;
				offerCounter.levelNum = levelNum;
				addChild(offerCounter);
			}
		}
	}
}
