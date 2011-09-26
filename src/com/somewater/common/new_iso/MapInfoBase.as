package com.somewater.common.new_iso
{
	/**
	 * Базовый класс для хранения информации о карте и объектах на ней
	 */	
	public class MapInfoBase
	{
		/* Ширина карты. */
		public var width:uint;
		
		/* Высота карты. */
		public var height:uint;
		
		/* Массив тайлов. */
		public var terrain:Array;
		
		/* Массис с информацией о объектах принадлежащи карте. */
		public var objects:Array;
			
		public function MapInfoBase(_width:uint, _height:uint, _terrain:Array, _objects:Array)
		{
			width = _width;
			height = _height;
			terrain =_terrain;
			objects = _objects;
		}
	}
}