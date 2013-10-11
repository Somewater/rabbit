package com.somewater.rabbit.decor {
	import com.pblabs.engine.PBE;
	import com.pblabs.rendering2D.DisplayObjectRenderer;
	import com.somewater.rabbit.iso.IsoRenderer;
	import com.somewater.rabbit.storage.Config;
	import com.somewater.effects.IEffect;
	import flash.geom.Point;

	/**
	 * Управляет всплывающими эффектами игры, которые проигрывают свою анимацию единожды и умирают
	 */
	public class EffectRenderer extends DisplayObjectRenderer{
		
		public var slug:String;
		public var frameRate:Number = Config.FRAME_RATE;
		
		protected var _clipLastUpdate:uint;
		protected var tempIsoScreenPoint:Point = new Point();

		private var _effect:IEffect;
		
		public function EffectRenderer() {
			super();
			snapToNearestPixels = false;
		}

		override public function onFrame(elapsed:Number):void
		{
			if(!_displayObject)
			{
				_effect.start();
				displayObject = _effect.displayObject();
				if(owner)
					this.position = owner.getProperty(positionProperty) as Point;
                updateTransform();
			}

			var frameTime:Boolean = PBE.processManager.virtualTime - _clipLastUpdate + 1 >= 1000/frameRate;

			if(frameTime)
			{
				if(!_effect.tick(elapsed * 1000)){
					_owner.destroy();
				}
			}
		}


		public function get effect():IEffect {
			return _effect;
		}

		public function set effect(value:IEffect):void {
			_effect = value;
			_registrationPoint = _effect.getRegistrationPoint();
		}

		override protected function onRemove():void {
			super.onRemove();
			_effect.clear();
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
