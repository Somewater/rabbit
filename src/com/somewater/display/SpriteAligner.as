package com.somewater.display {
	import flash.display.DisplayObject;
	import flash.display.Sprite;
	import flash.geom.Rectangle;

	/**
	 * Выравнивает переданный target так, чтобы его (target) левый верхний угол совпадал с 0,0
	 */
	public class SpriteAligner extends Sprite{

		private var target:DisplayObject;
		private var targetWidth:int;
		private var targetHeight:int;

		public function SpriteAligner(target:DisplayObject) {
			this.target = target;
			addChild(target);

			var bounds:Rectangle = target.getBounds(target);
			targetWidth = bounds.width;
			targetHeight = bounds.height;
			target.x -= bounds.x;
			target.y -= bounds.y;
		}


		override public function get width():Number {
			return targetWidth * scaleX * target.scaleY;
		}


		override public function get height():Number {
			return targetHeight * scaleY * target.scaleY;
		}
	}
}
