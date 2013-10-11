package com.somewater.rabbit.application.effects {
	import com.somewater.effects.FountainEffect;
	import flash.geom.ColorTransform;

	public class GameFountainEffect extends FountainEffect{

		protected var renderClearColorTransform:ColorTransform;

		public function GameFountainEffect(visualTypes:Array) {
			super(visualTypes);
			clearBeforeRender = false;
			renderClearColorTransform = new ColorTransform(1,1,1,0.6);
			lifetime = 600;
			emitSpeed = 0.01;
			particleMaximum = 20;
		}

		override protected function render():void {
			bitmapData.colorTransform(bitmapData.rect, renderClearColorTransform)
			super.render();
		}
	}
}
