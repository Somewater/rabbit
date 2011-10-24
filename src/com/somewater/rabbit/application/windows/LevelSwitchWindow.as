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
	import com.somewater.utils.MovieClipHelper;

	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
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

		protected var starIcon:DisplayObjectContainer;
		protected var okButton:OrangeButton;

		public function LevelSwitchWindow() {
			super(null, null, null, []);

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


		override public function defaultButtonPress():void {
			onOkClicked(null);
		}

		private function onOkClicked(event:MouseEvent):void {
			onWindowClosed();
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

		protected function createTextAndImage(title:String, text:String = null, image:* = null):void
		{
			var titleTF:EmbededTextField = new EmbededTextField(null, 0xDB661B, 21);
			var tf:EmbededTextField = new EmbededTextField(Config.FONT_SECONDARY, 0x42591E, 14, true, true);
			var imageSource:*;

			if(image is DisplayObject)
				imageSource = image;
			else
				imageSource = getImage(image);

			addChild(titleTF);
			titleTF.htmlText = title;
			titleTF.x = (WIDTH - titleTF.width) * 0.5;
			titleTF.y = 45;


			addChild(tf);
			tf.x = 75;
			tf.y = 110;
			tf.width = (imageSource ? 245 : 445);
			tf.htmlText = text;

			if(tf.textHeight < 40 || tf.textWidth < tf.width * 0.8)
			{
				tf.x = tf.x + (tf.width - tf.textWidth) * 0.5
			}

			if(imageSource)
			{
				var border:DisplayObjectContainer = Lib.createMC("interface.LevelSwitchImage");
				border.x = 347;
				border.y = 115;
				addChild(border);

				var photo:Photo = new Photo(null, Photo.ORIENTED_CENTER, 175, 115, 185/2, 125/2);
				border.addChild(photo);
				photo.source = imageSource;
			}
		}

		private function getImage(image:String):*
		{
			if(image == null) return null;
			if(image.substr(0,7) == 'http://')
				return image;
			else if(image.substr(0,2) == 'T_' && Lang.t(image).substr(0,2) != 'T_')
				return getImage( Lang.t(image));
			else if(Lib.hasMC(image))
			{
				var mc:DisplayObject = Lib.createMC(image);
				if(mc is MovieClip)
					MovieClipHelper.stopAll(mc as MovieClip);
				return mc;
			}
			else
				return null;
		}

		protected function levelToString(level:LevelDef):String
		{
			return Lang.t("LEVEL_NUMBER", {"level": "<font size='36'>" + level.number + "</font>"});
		}
	}
}
