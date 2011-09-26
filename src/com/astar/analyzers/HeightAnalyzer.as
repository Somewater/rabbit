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
	import com.astar.Analyzer;
	import com.astar.IMap;
	

	/**
	 * The HeightAnalyzer allows the path to stay above or below certain heights or to have a minimum or maximum height difference between two tiles.
	 * @author Jeroen Beckers (info@dauntless.be)
	 */
	public class HeightAnalyzer extends Analyzer 
	{
		private var _maxDifference:Number;
		private var _minDifference:Number;
		
		private var _maxHeight:Number;
		private var _minHeight:Number;
		
		/**
		 * Creates a new HeightAnalyzer
		 * 
		 * @param maxDiff The maximum height difference
		 * @param minDiff The minimum height difference
		 * @param minHeight The minimum height
		 * @param maxHeight The maximum height
		 */
		public function HeightAnalyzer(minHeight:Number, maxHeight:Number, minDiff:Number, maxDiff:Number)
		{
			this._maxDifference = maxDiff;
			this._maxHeight = maxHeight;
			this._minDifference = minDiff;
			this._minHeight = minHeight;
		}
		
		override public function getTileInterface():Class
		{
			return IHeightTile;
		}
		
		override protected function analyze(mainTile : *, allNeighbours:Array, neighboursLeft : Array, map : IMap) : Array
		{
			var newLeft:Array = new Array();
			var mt:IHeightTile = mainTile as IHeightTile;
			
			for(var i:Number = 0; i<neighboursLeft.length; i++)
			{
				var currentTile : IHeightTile = neighboursLeft[i] as IHeightTile;
				if(currentTile.getHeight() >= this.getMinHeight() 
					&& currentTile.getHeight() <= this.getMaxHeight() 
					&& Math.abs(mt.getHeight() - currentTile.getHeight()) <= this.getMaxDifference() 
					&& Math.abs(mt.getHeight() - currentTile.getHeight()) >= this.getMinDifference())
					{
						newLeft.push(currentTile);
					}
					
			}
			return newLeft;
		}
		
		
		/**
		 * Returns the maximum height
		 * 
		 * @return The maximum height
		 */
		public function getMaxHeight() : Number {
			return _maxHeight;
		}
		
		/**
		 * Sets the maximum height
		 * 
		 * @param maxHeight The maximum height
		 */
		public function setMaxHeight(maxHeight : Number) : void {
			_maxHeight = maxHeight;
		}
		
		/**
		 * Returns the minimum height
		 * 
		 * @return The minimum height
		 */
		public function getMinHeight() : Number {
			return _minHeight;
		}
		
		
		/**
		 * Sets the minimum height
		 * 
		 * @param maxHeight The minimum height
		 */
		public function setMinHeight(minHeight : Number) : void {
			_minHeight = minHeight;
		}
		
		
		/**
		 * Returns the minimum difference
		 * 
		 * @return The minimum difference
		 */
		public function getMinDifference() : Number {
			return _minDifference;
		}
		
		/**
		 * Sets the minimum difference
		 * 
		 * @param maxHeight The minimum difference
		 */
		public function setMinDifference(minDifference : Number) : void {
			_minDifference = minDifference;
		}
		
		/**
		 * Returns the maximum difference
		 * 
		 * @return The maximum difference
		 */
		public function getMaxDifference() : Number {
			return _maxDifference;
		}
		
		/**
		 * Sets the maximum difference
		 * 
		 * @param maxHeight The maximum difference
		 */
		public function setMaxDifference(maxDifference : Number) : void {
			_maxDifference = maxDifference;
		}
	}
}
