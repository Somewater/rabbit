package com.somewater.common.new_iso
{
	import flash.geom.Point;

	/**
	 * Результат работы контроллеров типа DeciderController. Несет в себе информацию 
	 * о точке (тайле) или общем векторе, на который Decider советует переместить персонаж
	 * @see com.progrestar.common.controllers.DeciderController
	 * @see com.progrestar.common.controllers.IsoMoverController
	 * @author mister
	 */
	public class IsoDestination
	{
		public function IsoDestination(destination:IsoPoint = null, direction:Point = null, importance:Number = 1)
		{
			if(destination)
				this.destination = destination;
			
			if(direction)
				this.direction = direction;
			
			this.importance = importance;
		}
		
		/**
		 * Чётко определеная точка, куда следует послать персонажа
		 * (напр. сундук с золотом имеет чёткое положение и не меняет его)
		 */
		public var destination:IsoPoint;
		
		/**
		 * Направление, в котором следует пойти персонажу
		 * (напр. подальше от страшного волка)
		 * Как правило, указывает числ тайлов (по x, y) на которое желательно сместиться персонажу
		 */
		public var direction:Point;
		
		/**
		 * Значимость мнения контроллера в окончательном определении, куда перемещать персонаж [0...Number]
		 * importance = 1;// стандартная значимость
		 * importance = 0;// не обращать никакого внимания на это решение
		 */
		public var importance:Number;
		
		/**
		 * @return результат содержит какие-то полезные данные (destination или direction не равны нулю)
		 * (DeciderController может задать  их нулями, как знак того, что он не знает куда перемещать персонаж)
		 */
		public function isValid():Boolean{
			return destination || direction;
		}
		
	}
}