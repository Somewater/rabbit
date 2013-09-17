package com.somewater.rabbit.creature {
	import com.somewater.rabbit.components.HeroContactComponent;
	import com.somewater.rabbit.decor.PopupEffectFactory;
	import com.somewater.rabbit.events.OfferEvent;
	import com.somewater.rabbit.iso.IsoSpatial;
	import com.somewater.rabbit.storage.Config;

	/**
	 * Послать событие сбора оффера приложению и самоудалиться
	 */
	public class OfferControllerComponent extends HeroContactComponent{

		public var anumationSlug:String = 'rabbit.OfferBonusAnimation';

		override protected function onContact(heroSpatial:IsoSpatial):void {
			// диспатчить начисление еще одного оффера, передать событию координаты размещения оффера
			var spatial:IsoSpatial = owner.lookupComponentByName('Spatial') as IsoSpatial;
			Config.application.dispatchEvent(new OfferEvent(spatial.tile.x,  spatial.tile.y))

			// создать попап эффекта
			PopupEffectFactory.createEffect(anumationSlug, spatial.tile, this.owner);

			// и самоудалиться
			this.owner.destroy();
		}
	}
}
