package com.astar
{
	import com.astar.analyzers.FullClippingAnalyzer;
	import com.astar.analyzers.WalkableAnalyzer;
	
	import flash.geom.Point;

	public class SimpleAnalyzer
	{
		
		private var map		:	IMap;
		private var astar	:	Astar;
		private var dataMap	:	Array;
		
		private var onPathFound		: Function;
		private var onPathNotFound	: Function;
		
		
		public function SimpleAnalyzer(dataMap : Array=null, 
									   pFrom : Point=null, pTo : Point=null, 
									   onPathFound : Function=null, onPathNotFound:Function=null)
		{
			this.onPathFound = onPathFound;
			this.onPathNotFound = onPathNotFound;
			
			if(!dataMap) 
			{
				dataMap = [ [0,0,1,1,1,0],
							[0,0,0,0,1,0],
							[0,1,1,0,0,0],
							[0,0,0,0,1,0],
							[0,1,1,0,1,0],
							[1,1,0,0,0,0] ];
			}
			map = new Map(dataMap[0].length, dataMap.length);
			for(var y:Number = 0; y< dataMap.length; y++)
			{
				for(var x:Number = 0; x< dataMap[y].length; x++)
				{
					map.setTile(new BasicTile(1, new Point(x, y), (dataMap[y][x]==0)));
				}
			}
			
			astar = new Astar();
			
			astar.addAnalyzer(new FullClippingAnalyzer());
			astar.addEventListener(AstarEvent.PATH_FOUND, _onPathFound);
			astar.addEventListener(AstarEvent.PATH_NOT_FOUND, _onPathNotFound);
			
			if(!pFrom) pFrom = new Point(0, 0);
			if(!pTo) pTo = new Point(5, 5)
				
			astar.getPath(new PathRequest(pFrom, pTo, map));
		}
		
		private function _onPathFound(e : AstarEvent) : void {
			onPathFound && onPathFound(e.getPath());
		}
		
		private function _onPathNotFound(e : AstarEvent) : void {
			onPathNotFound && onPathNotFound();
		}
		
	}
}