package com.somewater.rabbit.components {
	import com.pblabs.engine.core.ObjectType;
	import com.pblabs.engine.entity.IEntity;
	import com.somewater.rabbit.iso.IsoMover;
	import com.somewater.rabbit.iso.IsoRenderer;

	import flash.filters.BitmapFilter;
	import flash.filters.GlowFilter;

	/**
	 * Собирает паверапы и контролирует их использование
	 */
	public class PowerupControllerComponent extends HarvesterComponent{

		private const PROTECTION:BitmapFilter = new GlowFilter(0xFFFFFF, 1, 5, 5, 10);
		private const SPEED_UP:BitmapFilter = new GlowFilter(0x0000FF, 1, 2, 2, 5);

		private var isoMoverRef:IsoMover;
		private var heroDataRef:HeroDataComponent;
		private var rendererRef:IsoRenderer;

		/**
		 * Массив временных паверапов
		 * array of PowerupInfo
		 */
		private var temporaryPowerups:Array = [];

		public function PowerupControllerComponent() {
			harvestType = new ObjectType('powerups');
		}


		override protected function onReset():void {
			super.onReset();

			if(isoMoverRef == null)
				isoMoverRef = owner.lookupComponentByName('Mover') as IsoMover;
			if(heroDataRef == null)
				heroDataRef = owner.lookupComponentByName('Data') as HeroDataComponent;
			if(rendererRef == null)
				rendererRef = owner.lookupComponentByName('Render') as IsoRenderer;
		}
		                                 ;

		override protected function onRemove():void {
			super.onRemove();
			isoMoverRef = null;
			heroDataRef = null;
			rendererRef = null;
			temporaryPowerups = [];
		}


		override public function onTick(deltaTime:Number):void {
			var i:int = 0;
			var filterDeleted:Boolean = false;
			while(i < temporaryPowerups.length)
			{
				var info:PowerupInfo = temporaryPowerups[i];
				info.timeRemain -= deltaTime;
				if(info.timeRemain <= 0)
				{
					// закончить действие паверапа
					var data:DataComponent = info.data;

					if(data.hasOwnProperty('protection'))
						heroDataRef.protectedFlag--;

					if(data.hasOwnProperty('speedAdd'))
						isoMoverRef.speed -= data.speedAdd;

					temporaryPowerups.splice(i, 1);
					filterDeleted = true;
				}
				else
				{
					// паверап еще не закончил действие, переходим к следующему
					i++
				}
			}

			if(filterDeleted)
				refreshActorPowerups();
		}

		/**
		 * Обработать собранные паверапы
		 * @param harvest
		 */
		override protected function applyHarvest(harvest:Array):void
		{
			for each(var entity:IEntity in harvest)
			{
				var data:DataComponent = entity.lookupComponentByName('Data') as DataComponent;

				if(data.hasOwnProperty('health'))
					heroDataRef.health = Math.min(1, heroDataRef.health + data.health);

				if(data.hasOwnProperty('protection'))
					heroDataRef.protectedFlag++;

				if(data.hasOwnProperty('speedAdd'))
					isoMoverRef.speed += parseFloat(data.speedAdd);

				if(data.hasOwnProperty('time'))
					pushToTemporaryPowerups(data);

				entity.destroy();
			}

			refreshActorPowerups();
			registerForTicks = temporaryPowerups.length > 0;
		}

		private function pushToTemporaryPowerups(data:DataComponent):void
		{
			var info:PowerupInfo = new PowerupInfo();
			info.data = data;
			info.timeRemain = (data.time || 0) * 0.001;
			temporaryPowerups.push(info);
		}

		/**
		 * Обновить визуальное состояние персонажа, в соответствии с действующимии паверапами
		 */
		private function refreshActorPowerups():void
		{
			var currentFilters:Array = [];
			for each(var info:PowerupInfo in temporaryPowerups)
			{
				if(info.data.hasOwnProperty('speedAdd') && currentFilters.indexOf(SPEED_UP) == -1)
					currentFilters.push(SPEED_UP);
				if(info.data.hasOwnProperty('protection') && currentFilters.indexOf(PROTECTION) == -1)
					currentFilters.push(PROTECTION);
			}
			rendererRef.displayObject.filters = currentFilters;
		}
	}
}

import com.somewater.rabbit.components.DataComponent;

class PowerupInfo
{
	public var data:DataComponent;
	public var timeRemain:Number;
}
