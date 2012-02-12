package com.somewater.rabbit.creature {
	import com.pblabs.engine.PBE;
	import com.pblabs.engine.entity.IEntity;
	import com.somewater.rabbit.components.FinderComponentBase;
	import com.somewater.rabbit.decor.PopupEffectFactory;
	import com.somewater.rabbit.events.OfferEvent;
	import com.somewater.rabbit.iso.IsoMover;
	import com.somewater.rabbit.iso.IsoSpatial;
	import com.somewater.rabbit.storage.Config;

	import flash.events.Event;

	public class OfferControllerComponent extends FinderComponentBase{

		private var heroEntityRef:IEntity

		public function OfferControllerComponent() {
			super();

			victimName = 'Hero';// всегда ищет только героя
			searchRadius = 0.25;
		}


		override protected function onAdd():void {
			super.onAdd();
			registerForTicks = true;
		}

		override protected function onRemove():void
		{
			super.onRemove()
			if(heroEntityRef)
				heroEntityRef.eventDispatcher.removeEventListener(IsoMover.TILE_REACHED, onHeroReachedTile);
			heroEntityRef = null;
		}

		/**
		 * В тике ищет героя, когда находит, отписывается от тиков
		 * @param deltaTime
		 */
		override public function onTick(deltaTime:Number):void {
			if(heroEntityRef == null)
			{
				heroEntityRef = PBE.lookupEntity(victimName);
				if(heroEntityRef == null)
					return;
				else
				{
					heroEntityRef.eventDispatcher.addEventListener(IsoMover.TILE_REACHED, onHeroReachedTile);
					registerForTicks = false;
				}
			}
		}

		/**
		 * Сверяет местоположение героя со своим и если местоположения пересекаются, самоудаляется и диспатчит сбор
		 */
		override public function analyze():void {
			var heroes:Array = searchVictims();
			if(heroes.length)
			{
				searchVictims();
				if(heroes.length > 1)
					throw new Error('Hero must be only one');

				// диспатчить начисление еще одного оффера, передать событию координаты размещения оффера
				var spatial:IsoSpatial = owner.lookupComponentByName('Spatial') as IsoSpatial;
				Config.application.dispatchEvent(new OfferEvent(spatial.tile.x,  spatial.tile.y))

				// создать попап эффекта
				PopupEffectFactory.createEffect('rabbit.OfferBonusAnimation', spatial.tile, this.owner);

				// и самоудалиться
				this.owner.destroy();
			}
		}

		private function onHeroReachedTile(e:Event):void
		{
			analyze();
		}
	}
}
