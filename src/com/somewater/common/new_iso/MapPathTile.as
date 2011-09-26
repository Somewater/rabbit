package com.somewater.common.new_iso
{
	import com.astar.BasicTile;
	import com.astar.Map;
	
	import flash.geom.Point;
	
	/**
	 * Информация о тайле карты, для A*
	 * Реализует Reachable тайла на основе маски 
	 * (проходимость тайла определяется конкретным объектом тайла, читающим маску)
	 * @author mister
	 */
	public class MapPathTile extends BasicTile
	{	
		/**
		 *	Суммарная маска всех элементов, которые находятся на выбранном тайле.
		 */	
		public var pathMask:uint = 0;
		
		/**
		 *	Маска доступных направлений.
		 * 	Нужна для многотайтловых объектов. 
		 * 	В какую строно по отношению к выбранному объекту нельзя двигаться -
		 * 	в каких соседних тайлах находиться этот же объект. 
		 * 
		 * 	Маска сопостовима с маской direction из MaskAnalyzer
		 */		
		public var directionMask:uint = 0;
		
		/**
		 *	Заполненность тайла
		 */		
		public var topLeft:Point;
		
		/**
		 *	Масксимальная высота среди всех объектов на тайле.
		 */		
		public var objectZ:int = 0;

		
		/**
		 * 	Специальное значение отображающее доступность этого тайла для объектов. 
		 * 	Для муверов недоступным считается только 0.
		 * 	Для mapObject все кроме 1.
		 *	0 - занятая область
		 * 	1 - ничего нет
		 * 	2 - область опасности создания замкнутой области 
		 */	
		public var reachableType:int = 0;
		
		public function MapPathTile(cost:Number, position:Point, mask:uint, inner:Point=null, _objectZ:int=0, directionMask:uint=0)
		{
			this.pathMask = mask;
			this.topLeft = inner;
			this.objectZ = _objectZ;
			this.directionMask = directionMask;
			
			super(cost, position, mask == 0);
		}
	}
}