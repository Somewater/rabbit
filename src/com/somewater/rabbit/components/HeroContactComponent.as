package com.somewater.rabbit.components {
	import com.pblabs.engine.PBE;
	import com.pblabs.engine.entity.IEntity;
	import com.somewater.rabbit.iso.IsoMover;
	import com.somewater.rabbit.iso.IsoSpatial;

	import flash.events.Event;

	/**
	 * Компонент ищет контакта с Героем, при контакте вызывает функцию onContact
	 */
	public class HeroContactComponent extends FinderComponentBase{

		private var heroEntityRef:IEntity

		public function HeroContactComponent() {
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

				onContact(heroes[0])
			}
		}

		private function onHeroReachedTile(e:Event):void
		{
			analyze();
		}

		/**
		 * Выполнить действие, на которое запрограммирован компонент
		 */
		protected function onContact(heroSpatial:IsoSpatial):void
		{
			throw new Error('Must be overriden')
		}
	}
}
