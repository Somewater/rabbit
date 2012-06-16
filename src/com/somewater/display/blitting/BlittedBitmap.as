package com.somewater.display.blitting {
	import flash.display.Bitmap;
	import flash.display.DisplayObject;
	import flash.display.Sprite;

	public class BlittedBitmap implements IBlitted{

		public var slug:String;

		/**
		 * Вовне передается именно холдер, чтобы иметь возможность менять координаты битмапа внутри холдера
		 */
		private var holder:Sprite;
		private var bitmap:Bitmap;

		private var blitManager:BlitManager;

		private var state:String;
		private var direction:int;
		private var frame:int;
		private var hash:String;

		public function BlittedBitmap() {
			super()

			bitmap = new Bitmap();

			holder = new Sprite();
			holder.addChild(bitmap)

			blitManager = BlitManager.instance;
		}

		public function initialize(slug:String):void {
			this.slug = slug;
		}

		public function goto(state:String, direction:int):void {
			this.state = state;
			this.direction = direction;
			frame = 1;
			hash = state + ":" + direction + ':' + frame;
			blitManager.getBlitData(this.slug, state, direction, frame, update);
		}

		public function next(frames:int = 1):void {
			var len:int = blitManager.getLength(this.slug, state, direction);
			if(len)
				frame = ((frame - 1 + frames) % len) + 1;
			else
				frame += frames;
			hash = state + ":" + direction + ':' + frame;
			blitManager.getBlitData(this.slug, state, direction, frame, update);
		}

		private function update(data:BlitData):void {
			if(data.hash == this.hash)
			{
				bitmap.bitmapData = data.bmp;
				bitmap.x = data.offsetX;
				bitmap.y = data.offsetY;
			}
		}

		public function get displayObject():DisplayObject {
			return holder;
		}
	}
}
