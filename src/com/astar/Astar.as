/*
*  	+-----------------------------------------------------------+
*	|			              _             					|
* 	|			    /\       | |            					|
* 	|			   /  \   ___| |_ __ _ _ __ 					|
* 	|			  / /\ \ / __| __/ _` | '__|					|
* 	|			 / ____ \\__ \ || (_| | |   					|
* 	|			/_/    \_\___/\__\__,_|_|   v1.0				|
* 	|															|
* 	+-----------------------------------------------------------+
* 	| 	Implementation by Jeroen Beckers a.k.a. Dauntless		|
* 	|	Website: http://www.dauntless.be/astar					|
* 	|	Contact: info@dauntless.be								|
* 	+-----------------------------------------------------------+
* 	|	Change log (dd/mm/yyyy):								|
* 	|		05/08/2008: 1.0 beta								|
*   |		09/11/2009: 1.1 									|
*	|		19/07/2010: 1.2
* 	+-----------------------------------------------------------+
* 	|	Do you want a feature, or do you know ways of 			|
* 	|	making the algorithm faster? Contact me!				|
* 	+-----------------------------------------------------------+
*/

/*
Copyright (c) 2008 Jeroen Beckers - http://www.dauntless.be

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
	import com.pblabs.engine.debug.Profiler;
	
	import flash.events.EventDispatcher;
	import flash.events.TimerEvent;
	import flash.geom.Point;
	import flash.utils.Dictionary;
	import flash.utils.Timer;
	

	/**
	 * The main search algorithm and core class of this Astar library.
	 * @author Jeroen Beckers (info@dauntless.be)
	 */
	public class Astar extends EventDispatcher
	{
		private var debug:Boolean = false;

		/**
		 * The diagonal factor is multiplied with the moving cost when moving in a diagonal fashion.
		 */
		public static const DIAGONAL_FACTOR : Number = 1.4;

		/**
		 * The standard cost for a tile. If a tile has no cost set (the tile does not implement the ICost interface), this value is used. 
		 * The value is also used for estimating the cost from one tile to the end (H Heuristic)
		 */
		private var _standardCost : Number = 1;

		/**
		 * The number of iterations to do within one timespan. For small maps, this can be equal to the total size (=number of tiles) of your maps.
		 * For bigger maps, you can use a lower value. (Default = 100)
		 */
		private var _iterations : Number = 1000;

		/**
		 * The interval that is used to schedule iteration sequences, expressed in milliseconds. (Default = 100)
		 */
		private var _intervalTime : Number = 100;

		/**
		 * A queue containing all the paths that have to be found.
		 */
		private var _queue : SortedQueue;
		 
		 /**
		* Indicates whether the there is being looked for a path or not
		*/
		private var _isSearching:Boolean = false;
		
		/**
		 * The datamap. Contains DataTile instances.
		 */
		private var _map:IMap;
		
		/**
		 * The source map
		 */
		private var _sourceMap:IMap;
		 
		/**
		 * Analyzers. The neighbours returned by the INeighboursCollector are passed through these analyzers to eliminate non-eligible neighbours 
		 */
		private var _analyzer : Analyzer;
		
		/**
		 * The start point
		 */
		private var _start:Point;
		 
		/**
		 * The end point
		 */
		private var _end:Point;
		
		
		/**
		 * The PathRequest that is being processed
		 */
		private var _currentRequest:PathRequest;
		  
		/**
		 * The heap stores all the tiles in the open list
		 */
		private var _heap:BinaryHeap;
		
		/**
		 * Indicates whether or not a path has been found.
		 */
		private var _pathFound:Boolean;

		/**
		 * Used for mapping the DataTiles to the tiles given by the user
		 */
		private var _dictionary : Dictionary;




		/**
		 * Creates a new Astar instance
		 */
		public function Astar()
		{
			_queue = new SortedQueue();
			_dictionary = new Dictionary(true);
		}



		/**
		 * Returns the standard cost for the tiles
		 * @return	The standard cost for a tile
		 */
		public function getStandardCost() : Number
		{
			return _standardCost;
		}

		/**
		 * Sets the standard cost for a tile.
		 * 
		 * @param 	standardCost	The stancard cost for a tile
		 */
		public function setStandardCost(standardCost : Number) : void
		{
			_standardCost = standardCost;
		}

		
		/**
		 * Starts searching for a new Path, if no other path is being calculated. The found path will be dispatched with 'Astar.PATH_FOUND'.
		 * @param	item	The PathRequest containing the search info
		 */
		public function getPath(item : PathRequest, debug:Boolean = false):void
		{
			
			this.debug = debug;
			
			//check if startpoint is valid, endpoint is valid, etc. Will throw AstarError on error
			if(ready(item))
			{				
				//add to the queue
				_queue.enqueue(item);
				
				//if not already searching, start searching
				if(!_isSearching) searchForNextPath();
			}else{
				if(item.callback != null)
					item.callback(new AstarEvent(AstarEvent.PATH_NOT_FOUND, null, item));
			}
		}
		

		/**
		 * Searches for the next path in the queue
		 */
		private function searchForNextPath() : void
		{
			//if there is no next assignment, stop
			if(!_queue.hasNext()) return;
			
			//set request, start, end & sourcemap
			this._currentRequest = _queue.getNext();
			_start = this._currentRequest.start;
			_end = this._currentRequest.end;
			
			this._sourceMap = this._currentRequest.map;
			
			//set flag
			this._isSearching = true;
			
			//create the data map
			createDataMap();
			

			
			_heap = new BinaryHeap(compareFValues);
			
			//no path found yet
			_pathFound = false;
			
			_analyzer.request = _currentRequest;
			
			//open the starting tile and add it to the heap
			openTile(getDataTile(_start.x, _start.y), _start, 0, _end, null);
			
			//initiate timer
			runCore();
		}
		
		
		
		/**
		 * The core is run when the Timer dispatches its TimerEvent.TIMER.
		 */
		public function runCore():void
		{
			if(_isSearching == false) return;
			
			CONFIG::debug
			{
				Profiler.enter("Astar.runCore");
			}
			var current : DataTile;
			
			var curPos:Point = null;
			var neighbours:Array = null;
			
			//while there are items left to inspect
			for(var i:int = 0; i<_iterations && this._heap.getLength() > 0; i++)
			{
				//get new item
				current = this._heap.shift();
				
				//check if destination is reached
				curPos = current.position;
				if(curPos.x == _end.x && curPos.y == _end.y)
				{
					_pathFound = true;
					break;
				}
				
				//close current tile
				current.setClosed();
				
				//get surrounding neighbours
				neighbours = getNeighbours(curPos);
				
				//inspect neighbours & act accordingly
				inspectNeighbours(current, neighbours);
			}
			
			//if the heap is empty and the path hasn't been found, or the path has been found
			if((_heap.getLength() == 0 && !_pathFound) || _pathFound)
			{
				
				var event:AstarEvent;
				
				if(!_pathFound)event = new AstarEvent(AstarEvent.PATH_NOT_FOUND, new AstarPath(), _currentRequest);
				else event = new AstarEvent(AstarEvent.PATH_FOUND, buildPath(), _currentRequest);

				this._isSearching = false;
				
				//dispatch event
				if(_currentRequest.callback != null)
					_currentRequest.callback(event);
					
				this.dispatchEvent(event);	
				
				
				//continue searching
				searchForNextPath();
			}
			//path is still being looked for...
			CONFIG::debug
			{
				Profiler.exit("Astar.runCore");
			}
		}
		
		/**
		 * Builds the path starting from the end and working its way back.
		 * 
		 * @return path The path from start to end.
		 */
		private function buildPath() : AstarPath
		{
			var path : AstarPath = new AstarPath();
			
			//start at the end
			var tile:DataTile = this.getDataTile(_end.x, _end.y);
			var pos:Point = _end;
			
			//work back
			while(!pos.equals(_start))
			{
				path.add(tile.target);
				tile = tile.parent;
				pos = tile.position;
			}
			
			//add start
			path.add(tile.target);
				
			return path;
		}
		
		
		/**
		 * Gets the datatile at the given location in the map. It returns null if the location is invalid.
		 * @param	x	x position of the tile
		 * @param	y	y position of the tile
		 * @return		Null if the location is invalid. Otherwise, it returns the tile at the given location
		 */
		private function getDataTile(x:int, y:int):DataTile
		{
			var newDT:DataTile = null;
			
			//valid location?
			if(x < 0 || y < 0 || x >= _sourceMap.getWidth() || y >= _sourceMap.getHeight())
			{
				return null;	
			}
			
			//has the datatile been created yet? If not, create it
			if(DataTile(_map.getTileAt(new Point(x, y))).target == null)
			{
				newDT = new DataTile(this.getStandardCost());
				newDT.setPosition(x, y);
				newDT.target = _sourceMap.getTileAt(new Point(x, y));
				_map.setTile(newDT);
			}
			return DataTile(_map.getTileAt(new Point(x, y)));
		}
		
		
		/**
		 * Checks to see if everything is ready and throws an error if not.
		 * 	- Start is within bounds
		 * 	- End is within bounds
		 * 	- Start != End
		 * 	- Start is valid
		 * 	- End is valid
		 * 	- Given tiles implement all interfaces
		 * 
		 */
		private function ready(item:PathRequest):Boolean
		{
			var start:Point = item.start, end:Point = item.end, map:IMap = item.map;
			if(start.x < 0 || start.x >= map.getWidth())
			{
				//abort("Start.x out of bounds");
				return false;
			}
			
			if(start.y < 0 || start.y >= map.getHeight())
			{
				//abort("Start.y out of bounds");
				return false;
			}
			
			if(end.x < 0 || end.x >= map.getWidth())
			{
				//abort("End.x out of bounds");
				return false;
			}
			
			if(end.y < 0 || end.y >= map.getHeight())
			{
				//abort("End.y out of bounds");
				return false;
			}
			
			if(end.x == start.x && end.y == start.y)
			{
				//abort("Start equals end");
				return false;
			}
			
			return true
		}
		
		/**
		 * Used to cast error
		 */
		private function abort(msg:String):void
		{
			throw new AstarError(msg);	
		}
		
		/**
		 * Creates the internal datamap and populates it with data tiles
		 */
		private function createDataMap() : void
		{
			//reset map
			_map = new Map(this._currentRequest.map.getWidth(), this._currentRequest.map.getHeight());
			var sc:Number = this.getStandardCost();

			var dt:DataTile = null;
			
			var y:int = 0;
			var x:int = 0;
			
			var c:Number = 0;
			var r:Number = 0;
			
			for(y = 0, c = this._sourceMap.getHeight(); y<c; y++)
			{
				for(x = 0, r = this._sourceMap.getWidth(); x<r; x++)
				{
					dt = new DataTile(sc);
					dt.setPosition(x, y);
					_map.setTile(dt);
				}
			}
		}

		/**
		 * Add an analyzer to the analyzer chain
		 * 
		 * @param analyzer	The analyzer to add to the analyzer chain
		 */
		public function addAnalyzer(analyzer : Analyzer) : void
		{
			if(_analyzer) analyzer.setSubAnalyzer(_analyzer);
			_analyzer = analyzer;
		}
		
		/**
		 * Inspects the neighbours array of the current tile.
		 * @param	current		The current tile that is being examined
		 * @param	neighbours	The array of neighbour tiles
		 */
		private function inspectNeighbours(current:DataTile, neighbours:Array):void
		{
			var i:Number = neighbours.length;
			var cN:DataTile = null;
			
			var newF:Number = 0;
			var pos:Number = 0;
			
			//loop through the array
			while(i-- > 0)
			{
				//not in open array?
				cN = neighbours[i] as DataTile;
				
				cN.setDiag(_map.isDiagonal(current.position, cN.position));
				
				if(!cN.open)
				{
					//add to open-array					
					openTile(cN, cN.position, current.g, this._end, current);
				}
				else
				{
					//already in open, check if F via current node is lower	
					newF = cN.calculateUpdateF(current.g); 
					if(newF < cN.f)
					{
						pos = this._heap.getPosition(cN);
						
						cN.parent = (current);
						cN.setG(current.g);
						this._heap.update_heap(pos);	
					}
				}
			}
		}
		
		
		/**
		 * Compares two tiles' F values. This method is used as the comparefunction in the binary heap
		 * @param	tile1	The first tile
		 * @param	tile2	The second tile
		 * @return	The difference in F value of tile1 en tile2
		 */
		private function compareFValues(tile1:DataTile, tile2:DataTile):Number
		{
			return tile1.g - tile2.g;
		}
		
		
		
		
		/**
		 * Opens a tile. The tile's position is set, it's added to the open list, the G and H are set and the parent is set. 
		 * Afterwards, the tile is added to the heap.
		 * 
		 * @param tile		The tile to apply the actions to
		 * @param pos		The position to set the tile to
		 * @param g			The G, the total cost from the start up untill this tile
		 * @param h			The H, the distance to the endpoint
		 * @param parent	The parent of the tile
		 */
		private function openTile(tile:DataTile, pos:Point, g:Number, h:Point, parent:DataTile):void
		{
			tile.setPosition(pos.x, pos.y);
			tile.setOpen(true);
			tile.setG(g);
			tile.setH(h);
			tile.parent = parent;
			
			this._heap.add(tile);
		}
		
		/**
		 * Returns all the neighbours of the specified tile. Each neighbour is passed through the analyzer chain to see if it is valid
		 * 
		 * @param pos The position of the tile to get the neighbours for
		 * 
		 * @return 		The neighbours that passed the analyzers
		 */
		private function getNeighbours(pos:Point):Array
		{
			var allNeighbours:Array = getStandardNeighbours(pos);
			
			var neighboursToPass:Array = new Array();
			
			var nb:DataTile = null;
			
			//sub analyzers don't need the data tiles
			_dictionary = new Dictionary(true);
			for(var i:int = 0; i<allNeighbours.length; i++)
			{
				// dict[tile] = datatile
				nb = allNeighbours[i] as DataTile;
				this._dictionary[nb.target] = allNeighbours[i] as DataTile;
				neighboursToPass.push(nb.target);
			}
			
			//pass array through to all analyzers			
			var analyzedNeighbours:Array = _analyzer.subAnalyze(getDataTile(pos.x, pos.y), neighboursToPass, neighboursToPass, _sourceMap);
			
			
			//turn all tiles back to DataTiles
			var finalNeighbours:Array = new Array();
			for(i = 0; i<analyzedNeighbours.length; i++)
			{
				finalNeighbours.push(_dictionary[(analyzedNeighbours[i])]);
			}
			return finalNeighbours;
		}
		
		
		/**
		 * Returns the standard neighbours of the tile, according to the source map's getNeighbours method.
		 * 
		 * @param pos The position for the tile to get the standard neighbours from
		 * @return	An array containing datatile instances representing the neighbour tiles
		 */
		private function getStandardNeighbours(pos:Point) : Array
		{
			//the map determines which tiles are neighbours of which tiles
			var potNeighbours:Array = this._sourceMap.getNeighbours(pos);
			
			//leave out all the tiles that are already closed
			var neighbours:Array = new Array();
			
			var tile:DataTile = null;
			var newPos:Point = null;
			
			var i:Number = 0;
			
			for(i=0; i<potNeighbours.length; i++)
			{
				newPos = (potNeighbours[i] as BasicTile).position;
				tile = this.getDataTile(newPos.x, newPos.y);
				if(tile != null && !tile.closed) neighbours.push(tile);
			} 
			
			return neighbours;
		}
		
		/**
		 * Sets the number of iterations done within 1 timespan.
		 * @param	iterations	The number of iterations
		 */
		public function setIterations(iterations : Number) : void {
			_iterations = iterations;
		}
		
		/**
		 * Sets the time between two consecutive iteration series.
		 * 
		 * @param	intervalTime	The time between two consecutive iteration series
		 */
		public function setIntervalTime(intervalTime : Number) : void {
			_intervalTime = intervalTime;
		}
		
		/**
		 * Отвязать аналайзеры для успешного GC
		 */
		public function end():void{
			if(_analyzer)
				_analyzer.end();
			_map = null;
		}
	}
}











