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
	import flash.events.Event;

	/**
	 * The AstarEvent is dispatched by the Astar class when the path has or hasn't been found.
	 * @author Jeroen Beckers (info@dauntless.be)
	 */
	public class AstarEvent extends Event
	{
		public static const PATH_FOUND:String = "pathFound";
		public static const PATH_NOT_FOUND:String = "pathNotFound";
		
		public var path:AstarPath;
		public var request : PathRequest;
		
		public function AstarEvent(type:String, path : AstarPath, request:PathRequest, bubbles:Boolean = false, cancelable:Boolean = false) 
		{
			super(type, bubbles, cancelable);
			this.path = path;
			this.request = request;
		}
		
		
		override public function clone():Event 
		{
			return new AstarEvent(this.type, this.path, this.request, this.bubbles, this.cancelable);
		}
	}
}
