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
	public class BinaryHeap 
	{		
		private var _compare : Function;
		private var _heap : Array;

		public function BinaryHeap(p_compare:Function = null)
		{
			if(p_compare == null)
			{
				this._compare = function(a:Number, b:Number):Number
				{
					return a-b;
				};
				
			}
			else
			{
				this._compare = p_compare;
			}
			
			_heap = new Array(null);
			
		}
		
		/**
		 * Returns an array representing the binary heap
		 */
		public function toArray():Array
		{
			return _heap;
		}
		
		/**
		 * Adds an object to the heap
		 */
		public function add(newObject:*) : void
		{
			_heap.push(newObject);
			
			var cp:Number = _heap.length-1; //cp = current position
			
			//as long as the item isnt in the first position
			while(cp!= 1)
			{
				var n:Number = Math.floor(cp/2);
				if(_compare(_heap[cp],_heap[n]) <= 0)
				{
					//switch 'm
					var t:* = _heap[n];
					_heap[n] = _heap[cp];
					_heap[cp] = t;
					cp = n;
				}
				else
				{
					//destination reached
					break;
				}
			}
		}
		
		/**
		 * Returns whether the given object is in the heap or not
		 */
		public function hasElement(element:*):Boolean
		{
			var i:Number = _heap.length;
			while(i-- > 0)
			{
				if(_heap[i] == element) return true;	
			}
			return false;
		}
		
		/**
		 * Returns the first item from the heap and removes it from the heap
		 */
		public function shift():*
		{			
			//lowest is stored at the beginning of the heap
			var lowest:* = _heap[1];
			
			//length = 2 -> heap is now empty
			if(_heap.length == 2)
			{
				_heap.pop();
			}
			else
			{
				//get last item and store it in 1st place
				_heap[1] = _heap.pop();
			}
			
			crawlDown(1);
			return lowest;
		}
		
		/**
		 * Returns the first item in the heap, but it doesn't remove it from the heap
		 */
		public function getLowest():*
		{
			return _heap[1];	
		}
		
		
		/**
		 * Moves an item up in the heap
		 */
		private function crawlUp(start:Number):void
		{
			var cp:Number = start;
			
			//as long as the item isnt in the first position
			while(cp != 1){
				var hcp:Number = Math.floor(cp/2);

				var _heapcp:* = _heap[cp];
				var _heaphcp:* = _heap[hcp];
				
				if(_compare(_heapcp, _heaphcp) <= 0){
					
					//if the current F is lower than or equal to its parent, switch them!
					var t:* = _heaphcp;
					_heap[hcp] = _heapcp;
					_heap[cp] = t;
					cp = hcp;
				} else {
					//destination reached!
					break;	
				}
			}
		}
		
		/**
		 * Moves an item down in the heap
		 */
		private function crawlDown(start:Number):void
		{
			var cp:Number = start;
			var np:Number;
			while(true)
			{
				np = cp;
				var dnp:Number = 2*np; //double np
				if(dnp-(-1) <= _heap.length -1)
				{
					if(_compare(_heap[np], _heap[dnp]) >= 0) cp = dnp;
					if(_compare(_heap[cp], _heap[dnp -(-1)]) >= 0) cp = dnp -(-1);
				}
				else if(dnp <= _heap.length - 1)
				{
					if(_compare(_heap[np], _heap[dnp]) >= 0) cp = dnp;
				}
				
				//if np has changed, switch 'm
				if(np != cp)
				{
					var t:* = _heap[np];
					_heap[np] = _heap[cp];
					_heap[cp] = t;
				}
				else
				{
					break;
				}
			}
			
		}
		
		public function update_heap(start:Number):void
		{
			
			//move up or down?
			
			if(start > 1 && _compare(_heap[start], _heap[Math.floor(start/2)]) <= 0)
			{
				//up!
				crawlUp(start);
			}
			else
			{
				//down	
				crawlDown(start);
			}
		}
		
		/**
		 * Returns the length of the heap
		 */
		public function getLength():Number
		{
			return (_heap.length -1);
		}
		
		public function getPosition(el:*):Number
		{
			for(var i:Number = 1; i<_heap.length; i++)
			{
				if(_heap[i] == el) return i;
			}
			
			return -1;
		}
		
	}
}
