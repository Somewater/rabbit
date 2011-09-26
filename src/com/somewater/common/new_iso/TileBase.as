package com.somewater.common.new_iso
{
	
	/**
	 * Базовый класс для создания плиток, из которых состоит карта.
	 * @author mister
	 */	
	public class TileBase
	{
		/**
		 * Ссылка на объек карты, которой принадлежит данный тайл
		 */
		public var map:MapBase;
		
		/**
		 * Позиция тайла в тайловой системе координат
		 */
		public var position:IsoPoint;
		
		/**
		 * Маска, налагаемая на pathfinding текущим тайлом
		 * (если 0x0, то тайл нерпоходим, если 0xFFFFFFFF, значит тайл проходим кем и как угодно)
		 */
		public var pathMask:uint = 0;
		
		
		public function TileBase(position:IsoPoint)
		{
			this.position = position;
		}
		
		/**
		 * Удаляет из экземпляра TileBase все ссылки, мешающие GC
		 * (напр. зануляет map)
		 * Расширения данного класса дожны переопределить этот метод, если они хранят в себе еще какие-то типизированные структуры
		 */
		public function end():void{
			map = null;
			position = null;
		}
	}
}