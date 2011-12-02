package com.somewater.rabbit.decor {
	import com.pblabs.engine.PBE;
	import com.somewater.rabbit.iso.IsoRenderer;
	import com.somewater.rabbit.storage.Lib;

	import flash.geom.Point;

	/**
	 * Управляет всплывающими эффектами игры, которые проигрывают свою анимацию единожды и умирают
	 */
	public class PopupEffectRenderer extends IsoRenderer{
		public function PopupEffectRenderer() {
		}

		override public function onFrame(elapsed:Number):void
		{
			if(!_displayObject)
			{
				if(slug)
					clip = Lib.createMC(slug);

				updateProperties();
                updateTransform();
			}

			var frameTime:Boolean = PBE.processManager.virtualTime - _clipLastUpdate + 1 >= 1000/frameRate;

			if(frameTime)
			{
				_clipLastUpdate = PBE.processManager.virtualTime;
				if(clip.currentFrame == clip.totalFrames)
					owner.destroy();
				else
					clip.nextFrame();
			}

		}
	}
}
