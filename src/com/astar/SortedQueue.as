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

	/**
	 * @private
	 * @author Jeroen Beckers (info@dauntless.be)
	 */
	public class SortedQueue 
	{
		private var _queue : Array;

		/**
		 * Creates a new SortedQueue
		 */
		public function SortedQueue()
		{
			_queue = new Array();	
		}

		/**
		 * Checks if the queue has another object
		 * 
		 * @return 	A boolean indicating if the queue has another object
		 */
		public function hasNext() : Boolean
		{
			return _queue.length > 0;
		}

		/**
		 * Returns the next PathRequest without deleting it from the queue
		 * 
		 * @return The next PathRequest
		 */
		public function peek() : PathRequest
		{
			if(!hasNext()) return null;
			return _queue[0];
		}


		/**
		 * Returns the next PathRequest and deletes it fromt he queue
		 * 
		 * @return The next PathRequest
		 */
		public function getNext() : PathRequest
		{
			if(!hasNext()) return null;
			var ob : PathRequest = _queue.shift();	
			return ob;
		}


		/**
		 * Adds an item to this queue
		 * 
		 * @param item 		The PathRequest to add to this queue
		 */
		public function enqueue(item : PathRequest) : void
		{
			_queue.push(item);
			_queue.sortOn("priority", Array.NUMERIC);
		}
	}
}
