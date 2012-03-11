package com.somewater.rabbit.application.shop {
	import com.somewater.control.IClear;
	import com.somewater.display.HintedSprite;
	import com.somewater.rabbit.storage.Config;
	import com.somewater.rabbit.storage.ItemDef;
	import com.somewater.rabbit.storage.Lib;
	import com.somewater.text.EmbededTextField;
	import com.somewater.utils.MovieClipHelper;

	import flash.display.DisplayObject;

	import flash.display.MovieClip;

	import flash.display.Sprite;
	import flash.geom.Rectangle;

	/**
	 * Сдужит для создания иконки объекта и, если надо, счетчика кол-ва
	 */
	public class ItemIcon extends HintedSprite implements IClear{

		public static const HEIGHT:int = 48;

		public var item:ItemDef;

		private var image:DisplayObject;
		private var quantityTF:EmbededTextField;
		private var _quantity:int = 1;
		private var _background:DisplayObject;

		public function ItemIcon(item:ItemDef) {
			this.item = item;

			const imageScale:Number = 0.7;

			image = Lib.createMC(item.slug);
			if(image is MovieClip) MovieClipHelper.stopAll(image as MovieClip);
			image.scaleX = image.scaleY = imageScale;
			addChild(image);

			var bounds:Rectangle = image.getBounds(image);
			image.x = -bounds.x * imageScale;
			image.y = MyPowerupsBag.HEIGHT - 10;

			quantityTF = new EmbededTextField(Config.FONT_SECONDARY, 0xFFFFFF, 16, true, false, false, false, 'right');
			quantityTF.x = image.width + 10;
			addChild(quantityTF);

			_background = Lib.createMC('interface.OpaqueBackground');
			_background.x = -5;
			_background.height = HEIGHT;
			addChildAt(_background, 0);
			_background.visible = false;

			hint = item.getTitle();

			quantity = _quantity;
		}

		public function clear():void {
			image = null;
			item = null;
			hint = null;
		}

		override public function get width():Number {
			return quantityTF.x + quantityTF.textWidth;
		}

		override public function get height():Number {
			return HEIGHT;
		}

		public function set quantity(value:int):void
		{
			_quantity = value;
			quantityTF.text = value.toString();
			_background.width = this.width + 10;
		}

		public function get quantity():int
		{
			return _quantity;
		}

		public function set quantituColor(color:uint):void
		{
			quantityTF.color = color;
		}

		public function set background(value:Boolean):void
		{
			_background.visible = value;
		}
	}
}
