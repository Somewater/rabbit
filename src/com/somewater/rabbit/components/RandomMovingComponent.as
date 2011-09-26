package com.somewater.rabbit.components
{
	import com.pblabs.engine.components.ThinkingComponent;
	import com.pblabs.engine.entity.EntityComponent;
	import com.pblabs.engine.entity.PropertyReference;
	import com.somewater.rabbit.iso.IsoMover;
	import com.somewater.rabbit.util.RandomizeUtil;
	
	import flash.events.Event;
	import flash.geom.Point;
	
	/**
	 * Заставляет персонажа время от времени менять позицию
	 */
	public class RandomMovingComponent extends RandomActComponent
	{
		private var positionRef:PropertyReference;
		private var destinationRef:PropertyReference;
		
		/**
		 * Макс. расстояние перемещения в стейте перемещения
		 */
		public var radius:int = 3;
		
		override protected function onAdd():void
		{
			super.onAdd();
			owner.eventDispatcher.addEventListener(IsoMover.DESTINATION_SUCCESS, onRandomActEnd);
			owner.eventDispatcher.addEventListener(IsoMover.DESTINATION_ERROR, onRandomActEnd);
		}
		
		override protected function onRemove():void
		{
			super.onRemove();
			owner.eventDispatcher.removeEventListener(IsoMover.DESTINATION_SUCCESS, onRandomActEnd);
			owner.eventDispatcher.removeEventListener(IsoMover.DESTINATION_ERROR, onRandomActEnd);
		}
		
		public function RandomMovingComponent()
		{
			super();
			
			positionRef = new PropertyReference("@Spatial.tile");
			destinationRef = new PropertyReference("@Mover.destination");
		}
		
		override protected function randomAct():void
		{
			if(!_owner) return;
			
			var tile:Point = owner.getProperty(positionRef);
			if(tile)
			{
				tile = RandomizeUtil.RandomTilePoint_near(tile, radius);
				owner.setProperty(destinationRef, tile);
			}
			else
				planeRandomAct();
		}
	}
}