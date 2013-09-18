package com.somewater.rabbit.application.windows {
	import com.somewater.display.Photo;
	import com.somewater.display.Window;
	import com.somewater.rabbit.application.OrangeButton;
	import com.somewater.rabbit.social.PostingFactory;
	import com.somewater.rabbit.storage.Config;
	import com.somewater.rabbit.storage.LevelDef;
	import com.somewater.rabbit.storage.LevelInstanceDef;
	import com.somewater.rabbit.storage.Lib;
	import com.somewater.storage.Lang;
	import com.somewater.text.EmbededTextField;
	import com.somewater.utils.MovieClipHelper;
	
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Rectangle;
	import flash.text.TextField;

	public class LevelSwitchWindow extends WindowWithImage{

		protected var level:LevelDef;
		protected var levelInstance:LevelInstanceDef;

		protected var starIcon:DisplayObjectContainer;
		protected var okButton:OrangeButton;

		public function LevelSwitchWindow() {
			super(null, null, null, []);

			setSize(WIDTH, HEIGHT);

			createContent();

			createButtons();

			individual = true;
			open();

			closeButton.removeEventListener(MouseEvent.CLICK, onCloseBtnClick);
			closeButton.addEventListener(MouseEvent.MOUSE_DOWN, onCloseBtnClick);
		}

		protected function createButtons():void
		{
			if(okButton == null)
				okButton = new OrangeButton();
			okButton.label = Lang.t("OK");
			if(okButton.width < 125)
				okButton.width = 125;
			okButton.x = (width - okButton.width) * 0.5;
			okButton.y = height - okButton.height - 40;
			addChild(okButton);
			okButton.addEventListener(MouseEvent.MOUSE_DOWN, onOkClicked);
		}


		override public function defaultButtonPress():void {
			onOkClicked(null);
		}

		private function onOkClicked(event:MouseEvent):void {
			onWindowClosed();
			close();
			event.stopImmediatePropagation();
		}

		protected function createContent():void {

		}

		protected function onWindowClosed(e:Event = null):void
		{
			// продолжить игру
		}

		override protected function onCloseBtnClick(e:MouseEvent):void {
			super.onCloseBtnClick(e);
			e.stopImmediatePropagation();
		}

		override public function clear():void {
			level = null;
			levelInstance = null;
			okButton.removeEventListener(MouseEvent.MOUSE_DOWN, onOkClicked)
			okButton.clear();
			super.clear();
			closeButton.removeEventListener(MouseEvent.MOUSE_DOWN, onCloseBtnClick);
		}

		protected function createIcon(starIcon:DisplayObject):void
		{
			this.starIcon = starIcon as DisplayObjectContainer;
			var starIconMask:DisplayObject = Lib.createMC("interface.LevelStarIcon_mask");
			addChildAt(starIconMask, getChildIndex(ground) + 1);
			addChildAt(starIcon, getChildIndex(starIconMask) + 1);
			starIcon.x = -55;
			starIcon.y = -28;
			starIcon.mask = starIconMask;
		}

		protected function levelToString(level:LevelDef):String
		{
			return Lang.t("LEVEL_NUMBER", {"level": "<font size='36'>" + level.number + "</font>"});
		}
	}
}
