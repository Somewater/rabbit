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
	 * A simple Map implementation for the IMap interface
	 * @author Jeroen Beckers (info@dauntless.be)
	 */
	public class Map implements IMap 
	{
		public var _map:Array;
		
		
		/**
		 * Creates a new Map object with the specified width en height
		 * 
		 * @param width The width of the map
		 * @param height The height of the map
		 */
		public function Map(width:Number, height:Number)
		{
			this.setSize(width, height);
		}
		public function clone():Map{
			var m:Map = new Map(_map.length,_map[0].length);
			for (var i:int=0;i<_map.length;i++){
				for (var j:int = 0; j<_map[i].length; j++){	
					var b:BasicTile = getTileAt(new Point(i,j));
					m.setTile(b.clone());
				}
			}
			return m;
		}
		/**
		 * Returns the IPositionTile at the given location
		 * 
		 * @param position	The point specifing the location for the tile
		 * @return IPositionTile at the given location
		 */
		public function getTileAt(position : Point) : BasicTile
		{
			if(isValidPosition(position))
			{
				return _map[position.y][position.x];
			}
			return null;
		}
		
		/**
		 * Sets the given tile at the given location
		 * 
		 * @param tile		The tile to place in the map
		 */
		public function setTile(tile : BasicTile) : void
		{
			var pos:Point = tile.position
			if(isValidPosition(pos))
			{
				_map[pos.y][pos.x] = tile;	
			}
		}
		
		/**
		 * Returns the height of the map
		 * 
		 * @return The height of the map
		 */
		public function getHeight() : Number
		{
			return (_map == null)? -1 : _map.length;
		}
		
		/**
		 * Returns the width of the map
		 * 
		 * @return The width of the map
		 */
		public function getWidth() : Number
		{
			return (_map == null)? -1 : (_map[0] as Array).length;
		}
		
		
		/**
		 * Sets the size of the map
		 * 
		 * @param width 	The width of the map
		 * @param height 	The height of the map
		 */
		public function setSize(width : Number, height : Number) : void
		{
			_map = new Array(height);
			for(var i:Number = 0; i<height; i++)
			{
				_map[i] = new Array(width);	
			}
		}
		
		/**
		 * Returns whether or not the given position is located within the map
		 * 
		 * @param position The position to check
		 * 
		 * @return A boolean indicating if the given position is located within the map
		 */
		public function isValidPosition(position:Point):Boolean
		{
			if(_map == null) return false;
			if(position.x < 0 || position.y < 0) return false;
			if(position.x >= this.getWidth() || position.y >= this.getHeight()) return false;
			return true;
		}
		
		/**
		 * Returns an array with the neighbours of the given tile.
		 * 
		 * @param position The position of the tile to get the neighbours of
		 * 
		 * @return An array containing all the neighbouring tiles
		 */
		public function getNeighbours(position : Point) : Array
		{
			var x:Number = position.x;
			var y:Number = position.y;
			
			var neighbours:Array = new Array();
			if(this.isValidPosition(new Point(x-1, y-1))) neighbours.push(this.getTileAt(new Point(x-1, y-1)));
			if(this.isValidPosition(new Point(x-1, y))) neighbours.push(this.getTileAt(new Point(x-1, y)));
			if(this.isValidPosition(new Point(x-1, y+1))) neighbours.push(this.getTileAt(new Point(x-1, y+1)));
			if(this.isValidPosition(new Point(x, y-1))) neighbours.push(this.getTileAt(new Point(x, y-1)));
			if(this.isValidPosition(new Point(x, y+1))) neighbours.push(this.getTileAt(new Point(x, y+1)));
			if(this.isValidPosition(new Point(x+1, y-1))) neighbours.push(this.getTileAt(new Point(x+1, y-1)));
			if(this.isValidPosition(new Point(x+1, y))) neighbours.push(this.getTileAt(new Point(x+1, y)));
			if(this.isValidPosition(new Point(x+1, y+1))) neighbours.push(this.getTileAt(new Point(x+1, y+1)));
			
			
			return neighbours;
		}
		
		/**
		 * Checks if the given points are diagonal to eachother.
		 * 
		 * @param from 	The first point
		 * @param to	The second point
		 * 
		 * @return A boolean indicating if the given tiles are diagonal to eachother
		 */
		public function isDiagonal(from : Point, to : Point) : Boolean
		{
			return from.x != to.x && from.y != to.y;
		}
	}
}
