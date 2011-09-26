package com.astar
{
	
	import flash.geom.Point;
	
	public class BasicTile
	{
		/**
		 * Какая "почва" в тайле. Т.е. если в groundMask нет каких-то битов, 
		 * то они точно не появятся в этом тайле
		 */
		public var groundMask:uint = 0xFFFFFFFF;// абсолютно проходимый тайл
		
		/**
		 * Биты, оставшиеся от groundMask, после координации с объектами в тайле 
		 * (т.е. у mask некоторые биты могут быть выставлены в 0)
		 */
		public var mask:uint;
		
		/**
		 * Если не null, то для проверки проходимости тайла, вызывается данная функция
		 * hook(tile:BasicTile, spatial:IsoSpatial, startTile:Point):Boolean
		 * @return тайл проходим
		 */
		public var hook:Function;
		
		public var position:Point;
		
		public var x:int;
		public var y:int;
		
		public function BasicTile(position:Point = null)
		{
			this.position = position?position:new Point();
			
			x = this.position.x;
			y = this.position.y;
		}
		
		public function setPosition(x:int, y:int) : void
		{
			if(position == null)
				position = new Point(x, y);
			else
			{
				position.x = x;
				position.y = y;
			}
			
			x = this.position.x;
			y = this.position.y;
		}
		
		public function clone():BasicTile
		{
			var tile:BasicTile = new BasicTile(position);
			tile.mask = mask;
			tile.groundMask = groundMask;
			return tile;
		}
		
		
		public function toString():String
		{
			return "[BasicTile pos=" + (position?position.x.toFixed(1) + "," +  position.y.toFixed(1):"null") + ", mask=" + mask.toString(16) + ", gmask=" + groundMask.toString(16) + "]";
		}
	}
}