package com.somewater.rabbit.iso.astar
{
	import com.astar.BasicTile;
	import com.somewater.rabbit.iso.IsoSpatial;
	
	import flash.geom.Point;

	public interface IThinkWall
	{
		/**
		 * Занятость объектом тайлов может варьироваться и должна вычисляться индивидуально
		 */
		function getOccupyMask(x:int, y:int):int
			
		/**
		 * Объект сам определяет проходимость-непроходимость тайла
		 * независимо от наличия дугих объектов в нем
		 */
		function hook(tile:BasicTile, spatial:IsoSpatial, startTile:Point):Boolean
	}
}