package com.somewater.rabbit.decor {
	import com.pblabs.engine.PBE;
	import com.pblabs.engine.entity.IEntity;
	import com.pblabs.rendering2D.SimpleSpatialComponent;
	import com.somewater.rabbit.iso.IsoRenderer;

	import flash.geom.Point;

	public class PopupEffectFactory {
		public function PopupEffectFactory() {
		}

		public static function createEffect(animationSlug:String, tile:Point, invoker:IEntity):void
		{
			var effect:IEntity = PBE.templateManager.instantiateEntity('PopupEffect')
			effect.owningGroup = invoker.owningGroup;
			IsoRenderer(effect.lookupComponentByName('Render')).slug = animationSlug;
			SimpleSpatialComponent(effect.lookupComponentByName('Spatial')).position = tile;
		}
	}
}
