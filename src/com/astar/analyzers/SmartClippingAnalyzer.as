package com.astar.analyzers 
{
	import com.astar.Analyzer;
	import com.astar.IMap;
	import com.astar.IPositionTile;
	import com.astar.IWalkableTile;
	
	import flash.geom.Point;	
	

	
	/**
	 * The SmartClippingAnalyzer allows the path to go diagonal, but only if the adjecent horizontal & vertical tiles are free.
	 * If the path would go 'right + up', both 'right' and 'up' should be walkable
	 * @author Jeroen
	 */
	public class SmartClippingAnalyzer extends Analyzer 
	{
		public function SmartClippingAnalyzer()
		{
			super();
		}
		
		override protected function analyze(mainTile : *, allNeighbours:Array, neighboursLeft : Array, map : IMap) : Array
		{
			var main : IPositionTile = mainTile as IPositionTile;
			var mainPos : Point = main.getPosition();
			var newLeft:Array = new Array();
			for(var i:Number = 0; i<neighboursLeft.length; i++)
			{
				var currentTile : IPositionTile = neighboursLeft[i] as IPositionTile;
				var currentPos:Point = currentTile.getPosition();
				var tile:IWalkableTile;
				var tile2:IWalkableTile;
				
				if(currentPos.x == mainPos.x || currentPos.y == mainPos.y) newLeft.push(currentTile);
				else
				{
					if(currentPos.x < mainPos.x)
					{
						if(currentPos.y < mainPos.y)
						{
							tile = IWalkableTile(map.getTileAt(new Point(mainPos.x - 1, mainPos.y)));
							tile2 = IWalkableTile(map.getTileAt(new Point(mainPos.x, mainPos.y - 1)));
							if(tile.getWalkable() && tile2.getWalkable()) newLeft.push(currentTile);
						}
						else
						{
							tile = IWalkableTile(map.getTileAt(new Point(mainPos.x - 1, mainPos.y)));
							tile2 = IWalkableTile(map.getTileAt(new Point(mainPos.x, mainPos.y + 1)));
							if(tile.getWalkable() && tile2.getWalkable()) newLeft.push(currentTile);
						}
					}
					else
					{
						if(currentPos.y < mainPos.y)
						{
							tile = IWalkableTile(map.getTileAt(new Point(mainPos.x + 1, mainPos.y)));
							tile2 = IWalkableTile(map.getTileAt(new Point(mainPos.x, mainPos.y - 1)));
							if(tile.getWalkable() && tile2.getWalkable()) newLeft.push(currentTile);
						}
						else
						{
							tile = IWalkableTile(map.getTileAt(new Point(mainPos.x + 1, mainPos.y)));
							tile2 = IWalkableTile(map.getTileAt(new Point(mainPos.x, mainPos.y + 1)));
							if(tile.getWalkable() && tile2.getWalkable()) newLeft.push(currentTile);
						}
					}
				}
				
				if(currentTile.getPosition().x == main.getPosition().x || currentTile.getPosition().y == main.getPosition().y) newLeft.push(currentTile);
			}
			return newLeft;
		}
	}
}
