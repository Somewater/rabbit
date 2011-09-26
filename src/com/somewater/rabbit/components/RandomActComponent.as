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
	 * Заставляет персонажа время от времени выполнять какое-то действие
	 */
	public class RandomActComponent extends ThinkingComponent
	{
		/**
		 * Минимальное числор миллисекунд между движениями (ms)
		 */
		public var minTimeBetweenActs:int = 1000;
		
		/**
		 * Максимальное число миллисекунд между движениями (ms)
		 */
		public var maxTimeBetweenActs:int = 10000;
		
		public function RandomActComponent()
		{
			super();
		}
		
		override protected function onAdd():void
		{
			 planeRandomAct();
		}
		
		protected function planeRandomAct():void
		{
			think(randomAct, minTimeBetweenActs + (maxTimeBetweenActs - minTimeBetweenActs) * RandomizeUtil.rnd);
		}
		
		protected function randomAct():void
		{
			throw new Error("Must be overriden");
		}
		
		protected function onRandomActEnd(...args):void
		{
			planeRandomAct();
		}
	}
}