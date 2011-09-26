package com.somewater.rabbit.iso.astar
{
	import com.astar.Analyzer;
	import com.astar.BasicTile;
	import com.astar.IMap;
	import com.astar.PathRequest;
	import com.pblabs.engine.entity.IEntity;
	import com.pblabs.engine.entity.IEntityComponent;
	import com.somewater.rabbit.iso.IsoSpatial;
	import com.somewater.rabbit.iso.scene.IsoSpatialManager;
	
	import flash.geom.Point;
	
	public class IsoAnalyzer extends Analyzer
	{
		public var owner:IsoSpatial;
		public var passMask:int;
		public var directionMask:int;
		
		private var mainTile:BasicTile;
		private var mainPos:Point;
		
		public function IsoAnalyzer()
		{
			super();
			
			request = null;
		}
		
		override public function set request(value:PathRequest):void
		{
			_request = value;
			if(value)
			{
				owner = value.owner;
				passMask = owner.passMask;
				directionMask = value.directionMask;
			}else{
				// установить значения по умолчанию
				owner = null;
				passMask = 1;
				directionMask = 1;
			}
		}		
		
		override public function analyzeTile(tile:BasicTile, startTile:Point):Boolean
		{
			if(tile.hook != null)
				return tile.hook(tile, owner, startTile); 	// проследить соответствие
												 			// c IsoSpatialManager.analyzeTile
			else
				return (tile.mask & passMask) == passMask;			
		}
		
		override protected function analyze(mainTile:*, allNeighbours:Array, neighboursLeft:Array, map:IMap):Array
		{
			var i:int = 0;
			
			mainPos = BasicTile(mainTile).position;
			
			this.mainTile = mainTile as BasicTile;
			
			cycle:
			while(i < neighboursLeft.length) {
				
				var pos:Point = BasicTile(neighboursLeft[i]).position;
				var dx:Number = pos.x - mainPos.x;
				var dy:Number = pos.y - mainPos.y;
				
				if( (directionMask == 4 && (dx != 0 && dy != 0)) /*если запрещены диагонали и это диагональ*/
					|| 
					(directionMask == -4 && (dx ==0 || dy == 0) && dy <= 0) /*если разрешены ТОЛЬКО диагонали (и вниз) и это не диагональ и не движение вниз*/
				  )
				{
					neighboursLeft.splice(i, 1);
					continue cycle;
				}
				
				if(analyzeTile(neighboursLeft[i], mainPos))
				{
					// дополнительные проверки
				}
				else
				{
					neighboursLeft.splice(i, 1);
					continue cycle;
				}
				
				i++;
			}
			
			this.mainTile = null;
			mainPos = null;

			return neighboursLeft;
		}
	}
}