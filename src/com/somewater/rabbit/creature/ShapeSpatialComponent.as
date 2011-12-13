package com.somewater.rabbit.creature
{
	import com.astar.BasicTile;
	import com.pblabs.engine.components.TickedComponent;
	import com.pblabs.engine.entity.IEntityComponent;
	import com.pblabs.engine.entity.PropertyReference;
	import com.somewater.rabbit.iso.IsoRenderer;
	import com.somewater.rabbit.iso.IsoSpatial;
	import com.somewater.rabbit.iso.astar.IThinkWall;
	import com.somewater.rabbit.iso.scene.IsoSpatialManager;
	import com.somewater.rabbit.util.RandomizeUtil;
	
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	/**
	 * Обеспечивает неквадратную форму объектов
	 */
	final public class ShapeSpatialComponent extends IsoSpatial implements IThinkWall
	{
		public var shape:String = null;

		public function ShapeSpatialComponent()
		{
			occupyMaskRule = 1;// т.е. используем ф-ю getOccupyMask
		}
		
		public function getOccupyMask(x:int, y:int):int
		{
			if(shape == null)
				return occupyMask;
			// позиции запрашиваемого тайла в локальных координатах бревна
			x = x - int(_position.x);
			y = y - int(_position.y);
			if(shape == 'G')
			{
				// как русская (!) Г
				return x == 1 && y == 1 ? 0 : occupyMask;
			}
			else if(shape == 'R')
			{
				// как отраженная вертикально русская Г ( ^| )
				return x == 0 && y == 1 ? 0 : occupyMask;
			}

			throw new Error('Undefined shape ' + shape)
		}
		
		public function hook(tile:BasicTile, spatial:IsoSpatial, startTile:Point):Boolean
		{
			throw new Error('Not implemented');
		}
	}
}