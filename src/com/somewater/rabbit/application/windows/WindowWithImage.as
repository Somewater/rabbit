package com.somewater.rabbit.application.windows {
	import com.somewater.display.Photo;
	import com.somewater.display.Window;
	import com.somewater.rabbit.social.PostingFactory;
	import com.somewater.rabbit.storage.Config;
	import com.somewater.rabbit.storage.Lib;
	import com.somewater.text.EmbededTextField;

	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;

	/**
	 * Добавляет к классу Window ф-ю простого создания текста и тайтла, выравниваемых в присутствии картинки
	 */
	public class WindowWithImage extends Window{

		protected var titleTF:EmbededTextField;
		protected var tf:EmbededTextField;
		protected var border:DisplayObjectContainer;
		protected var photo:Photo;

		public function WindowWithImage(text:String = null, title:String = null ,closeFunc:Function = null,_buttons:Array = null) {
			super(text, title, closeFunc, _buttons)
		}

		protected function createTextAndImage(title:String, text:String = null, image:* = null):void
		{
			titleTF = new EmbededTextField(null, 0xDB661B, 21);
			tf = new EmbededTextField(Config.FONT_SECONDARY, 0x42591E, 14, true, true);
			tf.size = 14 + int(text && text.length ? (1 - Math.min(1,text.length / 200)) * 6 : 0)
			var imageSource:*;

			if(image is DisplayObject)
				imageSource = image;
			else
				imageSource = PostingFactory.getImage(image);

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
				border = Lib.createMC("interface.LevelSwitchImage");
				border.x = 347;
				border.y = 115;
				addChild(border);

				photo = new Photo(null, Photo.ORIENTED_CENTER, 175, 115, 185/2, 125/2);
				photo.photoMask = border.getChildByName('photoMask');
				photo.source = imageSource;
			}
		}

		protected function get WIDTH():int{
			return 600;
		}

		protected function get HEIGHT():int{
			return 400;
		}
	}
}
