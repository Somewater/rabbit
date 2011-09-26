package com.astar.analyzers
{
	import com.astar.IMap;
	import com.astar.IPositionTile;
	import com.astar.IWalkableTile;

	/**
	 *
	 * не ходим сквозь стены и по диагонали 
	 * 
	 * @author Victor Dmitriev 
	 */
	public class WalkableFullClippingAnalyzer extends FullClippingAnalyzer
	{
		public function WalkableFullClippingAnalyzer()
		{
			super();
		}
		
		override protected function analyze(mainTile : *, allNeighbours:Array, neighboursLeft : Array, map : IMap) : Array
		{
			var main : IPositionTile = mainTile as IPositionTile;
			
			var newLeft:Array = new Array();
			for(var i:Number = 0; i<neighboursLeft.length; i++)
			{
				
				var currentTile : IPositionTile = neighboursLeft[i] as IPositionTile;
				var w : IWalkableTile = neighboursLeft[i] as IWalkableTile;
				//only allow horizontal and vertical movement
				if(w.getWalkable() && 
					(currentTile.getPosition().x == main.getPosition().x || 
						currentTile.getPosition().y == main.getPosition().y)) {
					newLeft.push(currentTile);
					//trace(currentTile);
				}
			}
			
			return newLeft;
		}
		
	}
}