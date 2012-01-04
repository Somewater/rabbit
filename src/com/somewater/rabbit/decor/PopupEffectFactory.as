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
			var effect:IEntity = PBE.templateManager.instantiateEntity('PopupEffectTemplate')
			effect.owningGroup = invoker.owningGroup;
			PopupEffectRenderer(effect.lookupComponentByName('Render')).slug = animationSlug;
			tile = tile.clone();
			tile.x += 0.5;// чтобы попап плыл из середины тайла, а не из края 0,0
			tile.y += 0.5;
			SimpleSpatialComponent(effect.lookupComponentByName('Spatial')).position = tile;
		}
	}
}
