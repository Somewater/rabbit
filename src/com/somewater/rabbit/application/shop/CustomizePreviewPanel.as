package com.somewater.rabbit.application.shop {
	import com.somewater.control.IClear;
	import com.somewater.rabbit.application.CustomizeManager;
	import com.somewater.rabbit.storage.CustomizeDef;
	import com.somewater.rabbit.storage.Lib;
	import com.somewater.rabbit.storage.UserProfile;
	import com.somewater.utils.MovieClipHelper;

	import flash.display.DisplayObject;

	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.events.Event;

	public class CustomizePreviewPanel extends Sprite implements IClear, ICustomizable{

		private var core:MovieClip;
		private var hero:MovieClip;
		private var hole:MovieClip;

		private var customizeByTypes:Array = [];

		private var age:uint = 0;

		public function CustomizePreviewPanel() {
			core = Lib.createMC('interface.ShopHolePreview');
			addChild(core);

			var coreMask:DisplayObject = core.previewMask;
			addChild(coreMask);
			core.mask = coreMask;

			hole = Lib.createMC('reward.RabbitHole');
			MovieClipHelper.stopAll(hole);
			core.hole.addChild(hole);

			hero = Lib.createMC('rabbit.RabbitActor');
			hero.gotoAndStop(2);
			MovieClipHelper.stopAll(hero);
			core.hero.addChild(hero);

			addEventListener(Event.ENTER_FRAME, onTick);
		}

		private function onTick(event:Event):void {
			age++;

			if(age % 2 == 0 && hero)
			{
				var dir:MovieClip = hero.getChildAt(0) as MovieClip;
				dir.gotoAndStop(dir.currentFrame + 1 > dir.totalFrames ? 1 : dir.currentFrame + 1);
			}
		}

		public function clear():void
		{
			customizeByTypes = null;
			hero = null;
			hole = null;
			core = null;
			removeEventListener(Event.ENTER_FRAME, onTick);
		}

		/**
		 *
		 * @param items array of ItemDef
		 */
		public function show(items:Array):void {
			customizeByTypes = [];
			for each(var it:CustomizeDef in items)
				customizeByTypes[it.type] = it;
			CustomizeManager.instance.customizeHole(this, hole);
		}

		public function getCustomize(type:String):CustomizeDef {
			var it:CustomizeDef = customizeByTypes[type]
			if(!it)
				it = UserProfile.instance.getCustomize(type);
			if(!it)
				it = CustomizeDef.getDefault(type);
			return it;
		}
	}
}
