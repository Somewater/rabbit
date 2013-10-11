package com.somewater.rabbit.creature {
	import com.somewater.effects.IEffect;
	import com.somewater.rabbit.components.HeroContactComponent;
	import com.somewater.rabbit.decor.PopupEffectFactory;
	import com.somewater.rabbit.events.OfferEvent;
	import com.somewater.rabbit.iso.IsoSpatial;
	import com.somewater.rabbit.storage.Config;

	/**
	 * Послать событие сбора оффера приложению и самоудалиться
	 */
	public class OfferControllerComponent extends HeroContactComponent{

		public var animationSlug:String = 'rabbit.OfferBonusAnimation';
		public var offerType:int;

		override protected function onContact(heroSpatial:IsoSpatial):void {
			// диспатчить начисление еще одного оффера, передать событию координаты размещения оффера
			var spatial:IsoSpatial = owner.lookupComponentByName('Spatial') as IsoSpatial;
			Config.application.dispatchEvent(new OfferEvent(spatial.tile.x,  spatial.tile.y))

			// создать попап эффекта
			var effect:IEffect = Config.application.createEffect(animationSlug, {offerType: offerType})
			PopupEffectFactory.createEffect(animationSlug, spatial.tile, this.owner, true, effect);

			// и самоудалиться
			this.owner.destroy();
		}
	}
}
