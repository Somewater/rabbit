package com.somewater.rabbit.decor {
	import com.pblabs.engine.PBE;
	import com.pblabs.engine.entity.IEntity;
	import com.pblabs.engine.entity.IEntityComponent;
	import com.pblabs.rendering2D.SimpleSpatialComponent;
	import com.somewater.effects.IEffect;
	import com.somewater.rabbit.iso.IsoRenderer;
	import com.somewater.rabbit.storage.Config;

	import flash.geom.Point;

	public class PopupEffectFactory {
		public function PopupEffectFactory() {
		}

		public static function createEffect(animationSlug:String,tile:Point,
		                                    invoker:IEntity,
		                                    shiftHalf:Boolean = true,
		                                    preparedEffect:IEffect = null
											):void
		{
			var effect:IEntity = PBE.templateManager.instantiateEntity('PopupEffectTemplate')
			effect.owningGroup = invoker.owningGroup;
			var renderer:IEntityComponent = effect.lookupComponentByName('Render');
			if(renderer is PopupEffectRenderer){
				PopupEffectRenderer(renderer).slug = animationSlug;
			}else if(renderer is EffectRenderer){
				EffectRenderer(renderer).effect = preparedEffect || Config.application.createEffect(animationSlug);
			}
			tile = tile.clone();
			if(shiftHalf){
				tile.x += 0.5;// чтобы попап плыл из середины тайла, а не из края 0,0
				tile.y += 0.5;
			}
			SimpleSpatialComponent(effect.lookupComponentByName('Spatial')).position = tile;
		}
	}
}
