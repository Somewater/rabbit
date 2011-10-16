package com.somewater.rabbit.application.windows {
	import com.somewater.display.Photo;
	import com.somewater.display.Window;
	import com.somewater.rabbit.application.OrangeButton;
	import com.somewater.rabbit.storage.Config;
	import com.somewater.rabbit.storage.LevelDef;
	import com.somewater.rabbit.storage.LevelInstanceDef;
	import com.somewater.rabbit.storage.Lib;
	import com.somewater.storage.Lang;
	import com.somewater.text.EmbededTextField;

	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.Shape;
	import flash.display.Sprite;

	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.text.TextField;

	public class LevelSwitchWindow extends Window{

		protected const WIDTH:int = 600;
		protected const HEIGHT:int = 400;

		protected var level:LevelDef;
		protected var levelInstance:LevelInstanceDef;

		protected var starIcon:DisplayObject;
		protected var okButton:OrangeButton;

		public function LevelSwitchWindow() {
			super(null, null, onWindowClosed, []);

			setSize(WIDTH, HEIGHT);

			createContent();

			okButton = new OrangeButton();
			okButton.label = Lang.t("OK");
			if(okButton.width < 125)
				okButton.width = 125;
			okButton.x = (width - okButton.width) * 0.5;
			okButton.y = height - okButton.height - 40;
			addChild(okButton);
			okButton.addEventListener(MouseEvent.CLICK, onOkClicked);

			open();
		}

		private function onOkClicked(event:MouseEvent):void {
			close();
		}

		protected function createContent():void {

		}

		protected function onWindowClosed(e:Event = null):void
		{
			// продолжить игру
		}


		override public function clear():void {
			level = null;
			levelInstance = null;
			okButton.removeEventListener(MouseEvent.CLICK, onOkClicked)
			super.clear();
		}

		protected function createIcon(iconClass:Class):void
		{
			starIcon = new iconClass();
			var starIconMask:DisplayObject = Lib.createMC("todo");
			addChildAt(starIconMask, getChildIndex(ground) + 1);
			addChildAt(starIcon, getChildIndex(ground) + 1);
		}

		protected function createTextAndImage(title:String, text:String = null, image:String = null):void
		{
			var titleTF:EmbededTextField = new EmbededTextField(null, 0xDB661B, 21);
			var tf:EmbededTextField = new EmbededTextField(Config.FONT_SECONDARY, 0x42591E, 14, true, true);
			var imageDisplayObject:DisplayObject;

			if(image)
				imageDisplayObject = getImage(image);

			addChild(titleTF);
			titleTF.htmlText = title;
			titleTF.x = (WIDTH - titleTF.width) * 0.5;
			titleTF.y = 50;


			addChild(tf);
			tf.x = 75;
			tf.y = 105;
			tf.width = (imageDisplayObject ? 245 : 445);
			tf.htmlText = text;

			if(imageDisplayObject)
			{
				var border:DisplayObjectContainer = Lib.createMC("");
				border.x = 347;
				border.y = 115;
				addChild(border);

				var photo:Photo = new Photo(null, Photo.ORIENTED_CENTER | Photo.SIZE_MAX, 185, 125);
				border.addChild(photo);
				photo.source = imageDisplayObject;
			}
		}

		private function getImage(image:String):DisplayObject
		{
			var s:Sprite = new Sprite();
			s.graphics.beginFill(0);
			s.graphics.drawRect(0,0,50,100);
			s.graphics.beginFill(0xFF0000);
			s.graphics.drawRect(0,0,100,50)
			return s;
		}

		protected function levelToString(level:LevelDef):String
		{
			return Lang.t("LEVEL_NUMBER", {"level": "<font size='36'>" + level.number + "</font>"});
		}
	}
}
