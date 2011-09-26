/*
Copyright (c) 2008 Jeroen Beckers

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
*/

package com.astar.analyzers
{
	import com.astar.*;
	
	
	/**
	 * The WalkableAnalyzer eliminates tiles that aren't walkable.
	 * @author Jeroen
	 */
	public class WalkableAnalyzer extends Analyzer {
		public function WalkableAnalyzer() {
			super();
		}
		
		override public function getTileInterface():Class
		{
			return IWalkableTile;
		}
		
		override public function analyzeTile(tile: *):Boolean
		{
			return (tile as IWalkableTile).getWalkable();	
		}
		
		override protected function analyze(mainTile : *, allNeighbours:Array, neighboursLeft : Array, map : IMap) : Array
		{
			var newLeft:Array = new Array();
			for(var i:Number = 0; i<neighboursLeft.length; i++)
			{
				var currentTile : IWalkableTile = neighboursLeft[i] as IWalkableTile;
				if(currentTile.getWalkable()) newLeft.push(currentTile);
			}
			return newLeft;
		}
	}
	
	
}
