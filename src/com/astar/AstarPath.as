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

package com.astar 
{
	
	import flash.geom.Point;
	
	/**
	 * The AstarPath defines the path that is found by the Astar class.
	 * 
	 * @author Jeroen Beckers (info@dauntless.be)
	 */
	public class AstarPath implements IIterator
	{
		/**
		 * An array containing the path
		 */
		public var _path:Array;
		
		/**
		 * The position while traversing the path
		 */
		private var position:Number = 0;
		
		public function AstarPath(path:Array = null)
		{
			_path = path?path:[];
		}
		
		
		/**
		 * Adds a tile to the path
		 */
		internal function add(tile:BasicTile):void
		{
			this._path.splice(0, 0, tile);
		}
		
		/**
		 * Resets the position to 0
		 */
		public function reset() : void
		{
			position = 0;
		}
		
		/**
		 * Checks if there is a next node in the path
		 * 
		 * @return Boolean indicating if there is a next node
		 */
		public function hasNext() : Boolean
		{
			return position < _path.length;
		}
		
		
		/**
		 * Returns the current node without removing it from the path
		 * 
		 * @return The node on the current position in the path
		 */
		public function peek() : BasicTile
		{
			if(!hasNext()) return null;
			return _path[position];
		}
		
		
		/**
		 * Returns the current node from the path and removes it
		 * 
		 * @return The node on the current position in the path
		 */
		public function getNext() : BasicTile
		{
			if(!hasNext()) return null;
			return _path[position ++];
			
		}
		
		
		/**
		 * Returns a string representation of the path
		 * 
		 * @return A string representation of the path
		 */
		public function toString():String
		{
			var str:String = "AstarPath: ";
			for(var i:Number = 0; i<_path.length; i++)
			{
				var pos : Point = (_path[i] as BasicTile).position;
				str += "("+pos.x+","+pos.y+")";
				if(i < _path.length - 1) str += ",";
			}
			return str;
		}
		
		/**
		 * Returns an array representation of the path
		 * 
		 * @return An array containing the path
		 */
		 public function toArray():Array
		 {
		 	return _path.slice();
		 }
	}
}
