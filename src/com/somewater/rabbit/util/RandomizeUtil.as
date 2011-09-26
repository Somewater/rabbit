package com.somewater.rabbit.util
{
	import com.pblabs.engine.debug.Logger;
	import com.pblabs.engine.entity.IEntity;
	import com.pblabs.engine.entity.PropertyReference;
	import com.pblabs.engine.serialization.Serializer;
	import com.pblabs.engine.serialization.TypeUtility;
	import com.somewater.rabbit.iso.IsoSpatial;
	import com.somewater.rabbit.iso.scene.IsoSpatialManager;
	
	import flash.geom.Point;

	public class RandomizeUtil
	{
		private static var _randomizator:Number = 1;
		private static var spatialSize:PropertyReference = new PropertyReference("@Spatial.size");
		
		public static function initialize():void
		{
			TypeUtility.registerInstantiator("RandomTilePoint", RandomTilePoint);
			TypeUtility.registerInstantiator("RandomTilePoint.free", RandomTilePoint_free);
			_randomizator = Math.random();
			
			CONFIG::debug
			{
				_randomizator = 0.6;
			}
		}
		
		/**
		 * Возвращает тайловую (т.е. с ровными координатами) точку в пределах сцены
		 * @param paddingX, paddingY отступы от края, в котором не должны возвращаться точки 
		 * (применяется для генерации позиции имеющих размер персонажей, чтобы персонажи
		 * не вылезали за пределы карты)
		 */
		public static function RandomTilePoint(paddindX:int = 0, paddingY:int = 0):Point
		{
			CONFIG::debug
			{
				return new Point(int(rnd * (IsoSpatialManager.instance.width - paddindX)), 
								 int(rnd * (IsoSpatialManager.instance.height - paddingY)))
			}
			return new Point(int(Math.random() * IsoSpatialManager.instance.width - paddindX)
				, int(Math.random() * IsoSpatialManager.instance.height - paddingY));	
		}
		
		/**
		 * Аналогично RandomTilePoint, но пытается возвратить незанятую точку
		 */
		public static function RandomTilePoint_free():Point
		{
			var entity:IEntity = Serializer.instance.getCurrentEntity();
			var size:Point;
			if(entity)
			{
				size = entity.getProperty(spatialSize);
			}
			
			var paddingX:int = size?size.x:0;
			var paddingY:int = size?size.y:0;
			
			var point:Point;
			var counter:int = 0;
			do
			{
				point = RandomTilePoint(paddingX, paddingY);
				counter++;
			}while(!IsoSpatialManager.instance.pointIsFree(point.x, point.y) && counter < 100)
			
			if(counter >= 100)
				Logger.warn(RandomizeUtil, "RandomTilePoint_free", "Free point not founded. Counter overflow");
				
			return point;
		}
		
		/**
		 * Возвращает точку не далее заданного расстаяния от введенной точки
		 */
		public static function RandomTilePoint_near(current:Point, maxDistance:uint = 3):Point
		{
			var point:Point = new Point();
			var counter:int = 0;
			var maxDistanceSqr:Number =maxDistance * maxDistance;
			do
			{
				var dx:int = int((rnd - 0.5) * maxDistance);
				point.x = current.x + dx;
				point.y = current.y + int((rnd - 0.5) * (maxDistanceSqr - dx * dx));
				counter++;
			}while(!IsoSpatialManager.instance.pointIsFree(point.x, point.y) && counter < 100)
				
			if(counter >= 100)
				Logger.warn(RandomizeUtil, "RandomTilePoint_free", "Free point not founded. Counter overflow");
				
			return point;
		}
		
		
		public static function get rnd():Number
		{
			var r:Number = Math.pow(_randomizator + 3.1416, 8);
			_randomizator = r - int(r);
			return _randomizator;
		}
	}
}