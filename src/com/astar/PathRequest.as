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
	 * The PathRequest class describes a request to be handles by the Astar class.
	 * @author Jeroen Beckers (info@dauntless.be)
	 */

	
	
	public class PathRequest 
	{
		public var start : Point;
		public var end : Point;
		public var map : IMap;
		public var priority : uint;
		public var owner:*;
		public var callback:Function;
		public var directionMask:int;
		
		/**
		 * Creates a new PathRequest
		 * 
		 * @param start		The start point
		 * @param end		The end point
		 * @param map		The map to search in 
		 * @param priority	The priority of this request
		 */
		public function PathRequest(start : Point, end : Point, map : IMap, owner:*, callback:Function, directionMask:int ,priority : uint = 10) 
		{
			this.start = start;
			this.end = end;
			this.priority = priority;
			this.map = map;
			this.owner = owner;
			this.callback = callback;
			this.directionMask = directionMask;
		}
	}
}