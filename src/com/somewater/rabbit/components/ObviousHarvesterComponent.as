package com.somewater.rabbit.components {
	import com.pblabs.engine.entity.EntityComponent;
	import com.pblabs.engine.entity.IEntity;
	import com.somewater.rabbit.iso.IsoCameraController;
	import com.somewater.rabbit.iso.IsoSpatial;
	import com.somewater.rabbit.iso.scene.IsoSpatialManager;

	import flash.events.Event;

	import flash.geom.Point;

	/**
	 * Собирает урожай только в видимой игроку области карты
	 */
	public class ObviousHarvesterComponent extends HarvesterComponent{
		public function ObviousHarvesterComponent() {
		}


		/**
		 * Аналогично super ф-ции, но производит доп. проверку
		 * @param e
		 */
		override protected function onTileReached(e:Event):void
		{
			// самое время посомтреть, нет ли в новом тайле морковочки
			var harvestSpatials:Array = [];

			var newTile:Point = IsoSpatial(owner.lookupComponentByName("Spatial")).tile;
			tempQueryRectangle.x = newTile.x;
			tempQueryRectangle.y = newTile.y

			if(IsoSpatialManager.instance.queryRectangle(tempQueryRectangle, harvestType, harvestSpatials))
			{
				var i:int;
				var harvest:Array = [];
				for(i = 0;i<harvestSpatials.length;i++)
				{
					var entity:IEntity = EntityComponent(harvestSpatials[i]).owner;
					//
					//  ВНИМАНИЕ: доп. проверка на то, что собираемый объект находится в видимой области сцены
					//
					if(entity != owner && IsoCameraController.getInstance().isoSpatialInViewArea(harvestSpatials[i] as IsoSpatial))// самого себя не стоит собирать
						harvest.push(entity);
				}

				if(harvest.length)
				{
					if(sense)
					{
						// попросить разрешения на сбор
						_port(getSense(harvest, HARVEST_DETECTED));
					}
					else
						applyHarvest(harvest);
				}
			}
		}
	}
}
