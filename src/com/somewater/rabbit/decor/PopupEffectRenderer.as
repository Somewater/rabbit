package com.somewater.rabbit.decor {
	import com.pblabs.engine.PBE;
	import com.pblabs.rendering2D.DisplayObjectRenderer;
	import com.somewater.rabbit.iso.IsoRenderer;
	import com.somewater.rabbit.storage.Config;
	import com.somewater.rabbit.storage.Lib;
	
	import flash.display.MovieClip;
	import flash.geom.Point;

	/**
	 * Управляет всплывающими эффектами игры, которые проигрывают свою анимацию единожды и умирают
	 */
	public class PopupEffectRenderer extends DisplayObjectRenderer{
		
		public var slug:String;
		public var frameRate:Number = Config.FRAME_RATE;
		
		protected var _clipLastUpdate:uint;
		protected var _clipDirty:Boolean = false;
		protected var tempIsoScreenPoint:Point = new Point();
		
		public function PopupEffectRenderer() {
			super();
			snapToNearestPixels = false;
		}

		override public function onFrame(elapsed:Number):void
		{
			if(!_displayObject)
			{
				if(slug)
					clip = Lib.createMC(slug);

				//updateProperties();
				if(owner)
					this.position = owner.getProperty(positionProperty) as Point;

                updateTransform();
			}

			var frameTime:Boolean = PBE.processManager.virtualTime - _clipLastUpdate + 1 >= 1000/frameRate;

			if(frameTime)
			{
				_clipLastUpdate = PBE.processManager.virtualTime;
				if(clip.currentFrame == clip.totalFrames)
					owner && owner.destroy();
				else
					clip && clip.nextFrame();
			}
		}
		
		public function get clip():MovieClip
		{
			return this._displayObject as MovieClip;
		}
		
		public function set clip(value:MovieClip):void
		{
			if (value === displayObject)
				return;
			
			displayObject = value;
			_clipDirty = true;
		}

		override public function updateTransform(updateProps:Boolean = false):void
		{
			if(!_displayObject)
				return;
			
			if(updateProps)
				updateProperties();
			
			// If size is active, it always takes precedence over scale.
			var tmpScaleX:Number = _scale.x;
			var tmpScaleY:Number = _scale.y;
			
			_transformMatrix.identity();
			_transformMatrix.scale(tmpScaleX, tmpScaleY);
			_transformMatrix.translate(-_registrationPoint.x * tmpScaleX, -_registrationPoint.y * tmpScaleY);
			//_transformMatrix.rotate(_rotation * Math.PI * 0.0055555555555555555555 + _rotationOffset);
			tempIsoScreenPoint.x = _position.x + _positionOffset.x;
			tempIsoScreenPoint.y = _position.y + _positionOffset.y;
			IsoRenderer.isoToScreen(tempIsoScreenPoint);
			
			_transformMatrix.translate(tempIsoScreenPoint.x, tempIsoScreenPoint.y);
			_displayObject.transform.matrix = _transformMatrix;
			_displayObject.alpha = _alpha;
			_displayObject.blendMode = _blendMode;
			_displayObject.visible = (alpha > 0);
			
			_transformDirty = false;
		}
	}
}
