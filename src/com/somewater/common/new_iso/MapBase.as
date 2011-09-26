package com.somewater.common.new_iso
{
	import com.astar.Map;
	import com.somewater.common.global.Env;
	import com.somewater.common.new_iso.IsoPoint;
	import com.somewater.utils.Profiler;
	import com.progrestar.game.map.MapObject;
	
	import flash.display.MovieClip;
	import flash.display.Shape;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.utils.getTimer;
	import com.somewater.rabbit.iso.IsoObject;
	
	/**
	 * Обеспечивает базовые возможности тайловой карты:
	 * <li>Создает и корректно обновляет карту для pathfinding-а</li>
	 * <li>Внутри себя должна содержать только объекты типа MapObjectTiled</li>
	 * @see com.progrestar.common.new_iso.MapObjectTiled
	 * @author mister
	 */
	public class MapBase extends IsoContainer
	{
		/**
		 * Если появится необходимость создать тайлы картой (а не rpc), например юзер увеличил площадь карты,
		 * тайлы создаются на основе этого класса. Если в игре используется класс Tile->TileBase,то в рассматриваемую переменную
		 * нужно записать наиболее "современный" класс Tile
		 */
		protected var TILE_CLASS:Class = TileBase;
		
		/**
		 * Трехмерный массив вида objectsOnTile[x-tile][y-tile][object number] == MapObjectTiled
		 * для быстрого получения всех объектов, содержащихся в конкретном тайле
		 */
		public var objectsOnTile:Array;
		
		/**
		 * Двухмерный массив вида tiles[x-tile][y-tile] == TileBase
		 * для быстрого доступа к конкретному объекту типа Tile
		 */
		public var tiles:Array;
		
		/**
		 *	Массив объектов, которые ожидают освобождения тайла
		 */		
		public var addObjectQueue:Array;
		
		/**
		 * Ассоциативный массив координат тайлов 
		 * объекты в которых требуют переучёта (например, в карте path finding-а)
		 */
		internal var unregisteredTilesQueue:Array;
		internal var unregisteredReachableTilesQueue:Object;
		
		private var reachableMapInited:Boolean=false;
		
		protected var updateBorderQueue:Object;
		
		/**
		 * Карта для path finding-а при помощи A*
		 */
		public var pathFindingMap:com.astar.Map;
		
		// этот мувер используется локального перерасчета карты проходимости.
		protected var basicMover:IsoMover;
		
		protected var needCheckReachableTiles:Boolean = false;
		
		// потенциальная карта
		private var IslandsMap:Object;
		private var IslandsMapLinks:Object;
		
		/**
		 * Создать карту заданного размера (в тайлах)
		 * @param width
		 * @param height
		 */
		public function MapBase(_mapInfoBase:MapInfoBase)
		{
			unregisteredTilesQueue = [];
			unregisteredReachableTilesQueue = {};
			objectsOnTile = [];
			tiles = [];
			updateBorderQueue = {};
			setSize(_mapInfoBase.width, _mapInfoBase.height);
			
			numGrounds = 1;
			var sh:Shape = new Shape();
			sh.graphics.beginFill(0x33FF65);
			sh.graphics.lineStyle(2, 0xFF3333);
			addChild(sh);
			
			addObjectQueue = [];
		}
		
		/**
		 * Устанавливает для карты новый размер, в тайлах
		 * (или инициирует первоначальный размер для карты)
		 */
		public function setSize(w:int, h:int):void{
			if(_position.width != w || _position.height != h){
				var i:int; var j:int;
				
				// создать pathfinding map нового размера
				if(pathFindingMap)
					pathFindingMap.setSize(w, h);
				else
					pathFindingMap = new Map(w, h);
				
				// создание пустых тайлов
				for(i=0;i<w;i++)
					for(j=0;j<h;j++)
						pathFindingMap.setTile(new MapPathTile(1, new Point(i,j), 0));
				
				// обновить pathFindingMap (полностью)
				// обновить tiles и objectsOnTile (увеличить, если необходимо)				
				for(i = 0; i<w; i++){
					if(tiles[i] == null)
						tiles[i] = [];
					if(objectsOnTile[i] == null)
						objectsOnTile[i] = [];
					
					var column:Array = tiles[i];
					var objColumn:Array = objectsOnTile[i];
					
					for(j = 0; j<h; j++){
						var tile:TileBase;
						if(column[j] == null){
							tile = new TILE_CLASS(new IsoPoint(new Rectangle(i, j, 1, 1)));
							column[j] = tile;							
						}else tile = column[j];
						tile.map = this;
						if(objColumn[j] == null)
							objColumn[j] = [];
						unregisteredTilesQueue[i + (j << 16)] = true;
					}
				}
				
				if(tiles[0].length != w || tiles.length != h)
					throw new Error("Map resizing error. Map size=[" + tiles[0].length + "," + tiles.length + "], but required [" + w  + "," + h + "]");
				
				_position.width = w;
				_position.height = h;
				
				var s:String;
				for(s in unregisteredTilesQueue)
					refreshPathTile(uint(s));
				
				unregisteredTilesQueue = [];
				
			}
		}// end setSize
		
		
		public function addObjectInQueue(obj:IsoObject):void 
		{
			addObjectQueue.push(obj);
		}
		
		override public function addObject(object:IsoObject):Boolean{
			
			if(super.addObject(object)){
				if(object is MapObjectTiled)
					(object as MapObjectTiled).refreshMap();
				return true
			}
			return false;
		}
		
		override public function removeObject(object:IsoObject):void{
			super.removeObject(object);
			if(object is MapObjectTiled) {
				
				var mapObject:MapObjectTiled = (object as MapObjectTiled);
				
				if(mapObject.ghost)
					return;
				
				var one:int = int(mapObject.hasBorder);
				
				// обновить objectsOnTile, unregisteredTilesQueue и unregisteredReachableTilesQueue
				var pos:IsoPoint = object._position;
				var xPos:int = pos.x - (pos.x>0?one:0);
				var yPos:int = pos.y;
				var xMax:int = pos.right + (pos.x<position.width?one:0);
				var yMax:int = pos.bottom + (pos.y<position.height?one:0);

				do{
					yPos = pos.y - (pos.y>0?one:0);
					do{
						// мгновенное удаление
						if (objectsOnTile[xPos][yPos].indexOf(object)!=-1) 
							objectsOnTile[xPos][yPos].splice(objectsOnTile[xPos][yPos].indexOf(object),1);
						
						refreshPathTile(xPos + (yPos << 16));
						refreshReachableTile(xPos + (yPos << 16));
						
						yPos++;
					}while(yPos < yMax)
					xPos++;
				}while(xPos < xMax)
			} else
				throw new Error("MapBase must contain only objects of MapObjectTiled class");
			
			if(addObjectQueue.length>0)
			{
				for(var i:int=0;i<addObjectQueue.length;i++)
					addObjectQueueEngine(addObjectQueue[i]);
			}
		}
		
		override public function tick(time:int=0):void{
			Profiler.enter("MapBase.tick");
			
			var s:String;
			
			// обновить pathFindingMap на основе объектов из unsortedQueue
			for(s in unregisteredTilesQueue)
				refreshPathTile(uint(s));
			
			unregisteredTilesQueue = [];
			
			// обновление карты доступности
			for(s in unregisteredReachableTilesQueue)
				refreshReachableTile(uint(s));
			
			if(needCheckReachableTiles)
				checkClosedTiles();
			
			unregisteredReachableTilesQueue = {};
			
			// обновление границ вокруг некоторых объектов
			for(s in updateBorderQueue)
				createBorders(uint(s));
			
			updateBorderQueue = {};
			
//			if(addObjectQueue.length>0)
//			{
//				for(var i:int=0;i<addObjectQueue.length;i++)
//					addObjectQueueEngine(addObjectQueue[i]);
//			}
			
			// обеспечить прочую логику наследуемых классов
			super.tick(time);
			Profiler.exit("MapBase.tick");
		}
		
		override public function pointIsFree(isoPoint:Point, exclude:IsoObject=null):Boolean{
			// оптимизированная версия
			if(!_position.containsPoint(isoPoint)) return false;
			var objects:Array = objectsOnTile[int(isoPoint.x)][int(isoPoint.y)];
			for(var i:int = 0;i<objects.length;i++)
			{
				var object:MapObjectTiled = objects[i];
				if(object != exclude && (object is MapObjectBase))// только экземпляры MapObjectBase считаются занимающими место на карте, муверы не занимают место
					if(IsoObject(object)._position.containsPoint(isoPoint))
						return false;
			}
			return true;
		}
		
		override public function isoPointIsFree(isoRect:Rectangle, exclude:IsoObject=null):Boolean{
			// оптимизированная версия
			return tilesIsFree(isoRect, exclude, MapObjectBase);
		}
		
		override public function isoPointUninhabited(isoRect:Rectangle, exclude:IsoObject = null):Boolean{
			// оптимизированная версия
			return tilesIsFree(isoRect, exclude, IsoMover, false);
		}
		
		/**
		 * Проверяет, свободны ли тайлы карты, которые имеют пересечения с прямоугольником IsoPoint
		 * @param isoRect тестируемый прямоугольник в "тайловых" координатах (можно задлавать функции IsoPoint)
		 * @param exclude объект, который в процессе проверке не будет учтен, как занимающий место 
		 * (применяется для проверки возможности перемещения именно для этого объекта)
		 * @param testedClass если не null, то тестируются только объекты данного класса (или расширенные от него). Остальные объекты считаются незанимающие тайлы
		 * @wholeTile тестировать не пересечение прямоугольников, а сам факт нахождения 2-х объектов в пределе одного тайла (даже если размерные прямоугольники объектов не пересекаются)
		 * @return Определяет, занят ли прямоугольник каким-либо объектом в iso координатах
		 */
		public function tilesIsFree(isoRect:Rectangle, testObject:IsoObject=null, testedClass:Class = null, wholeTile:Boolean = false):Boolean
		{
			if(!isoRect)
				return false;
			
			var tempMapObjectTiled:MapObjectTiled;
			if(testObject && testObject is MapObjectTiled)
				tempMapObjectTiled = testObject as MapObjectTiled;					
			
			if(isoRect.x < 0 || isoRect.y < 0 || 
				Math.ceil(isoRect.right) > _position.width || 
				Math.ceil(isoRect.bottom) > _position.height)
				return false;
			
			var startX:int = int(isoRect.x);
			var stopX:int = Math.ceil(isoRect.right);
			var startY:int = int(isoRect.y);
			var stopY:int = Math.ceil(isoRect.bottom);
			if(startX == stopX) stopX++;
			if(startY == stopY) stopY++;
			for(var i:int = startX; i < stopX; i++)
				for(var j:int = startY; j < stopY; j++)
				{
					// первая проверка - если тайл считается недосягаемым, то ничего на него и не ставим
					if(!Env.editorMode && reachableMapInited)
					{
						if ((!testedClass || (testedClass && testedClass != IsoMover)) && 
							pathFindingMap["_map"][j][i]["reachableType"] != 1)
							return false;
					}
					
					var objects:Array = objectsOnTile[i][j];
					
					// вторая проверка 
					// если на тайле нет ни одого объекта, то только сравниваем маски проходимости
					if(objects.length == 0)
					{
						if(tempMapObjectTiled &&
							!MapObjectTiled.checkTileIsAvailable(
								tempMapObjectTiled.pathMask, pathFindingMap._map[j][i].pathMask))
							return false;
					}
					else
					{
						// третья провека со всеми объектами на тайле
						// за исключением себя
						for(var k:int = 0;k<objects.length;k++)
						{
							var object:MapObjectTiled = objects[k];
							
							if(object != testObject && (testedClass == null || object is testedClass))
							{
								// если нельзя допустить нахождение двух объектов на одном тайле
								if(wholeTile)
									return false;
								else
								{
									// не проверяем муверов 
									// это перестраховка - муверы уже не обновляют карту
									if(Env.unMoverGhosts && objects[k] is IsoMover)
										continue;
									
									// сравниваем маску проходимости и физ. размеры добавляемого объекта
									// с каждым объектом на тайле
									if(objects && tempMapObjectTiled && 
										!MapObjectTiled.checkTileIsAvailable(
											tempMapObjectTiled.pathMask, object.maskType,
											tempMapObjectTiled.pBottomRight, object.pTopLeft))
										return false;
									
									// простая провека пересечения двух прямоугольников
									if (object._position.intersects(isoRect))
										return false;
								}
							}
						}
					}
				}
			return true;
		}
		
		
		/**
		 * Возвращает все объекты, находящиеся на тайлах, занимаемых прямоугольником isoRect 
		 * @param isoRect прямоугольник, тайлы которого тестируются на предмет нахождения там объектов
		 * @param exclude исключаемый из ответа функции объект (как правило, сам мувер, вызывающий данную функцию)
		 * @param testedClass если задан, в ответ функции включаются только объекты данного класса (либо объекты, 
		 * 	      для которых заданный класс является наследуемым)
		 * @return массив объектов типа MapObjectTiled
		 * 
		 */
		public function getObjectsOnTiles(isoRect:Rectangle, exclude:IsoObject=null, testedClass:Class = null):Array
		{
			var response:Array = [];
			var k:int;
			var xPos:int = isoRect.x;
			var yPos:int;
			var stopX:int = Math.ceil(isoRect.right);
			var stopY:int = Math.ceil(isoRect.bottom);
			do{
				yPos = isoRect.y;
				do{
					var objects:Array = objectsOnTile[xPos][yPos];
					for(k = 0;k<objects.length;k++){
						var obj:MapObjectTiled = objects[k];
						if(response.indexOf(obj) == -1){
							if(exclude || testedClass){
								if(obj != exclude && (testedClass == null || (obj is testedClass)))
									response.push(obj);
							}else
								response.push(obj);
						}
					}					
					yPos++;
				}while(yPos < stopY)
				xPos++;
			}while(xPos < stopX)
			
			return response;
		}
		
		
		/**
		 * Обновляет информацию в конкретном тайле path finding map
		 * @param index координата тайла вида (x   +   y << 16)
		 */
		protected function refreshPathTile(index:uint):void
		{			
			var y:int = index >>> 16;
			var x:int = index & 0xFFFF;
						
			var mapTile:MapPathTile = (pathFindingMap._map[y][x] as MapPathTile);	
			
			var newMask:uint = 0;//mapTile.pathMask;
			var objects:Array = objectsOnTile[x][y];
			var newInnerRect:Point = new Point(1, 1);
			var newHeight:int = 0;
			var newDirectionMask:uint = 0;
			var getPoint:Point;
			
			for(var i:int = 0; i < objects.length; i++)
			{
				var objectTile:MapObjectTiled = (objects[i] as MapObjectTiled);
				// маска - максимальная маска среди объектов на тайле
								
				if(objectTile.ghost || (Env.unMoverGhosts && objectTile is IsoMover)) 
					continue;
				
				newMask = Math.max(newMask, objectTile.maskType);
				
				// заполненность тайла 
				// если есть мувер, то тайл весь заполнин 
				getPoint = objectTile.pTopLeft;
				
				if(getPoint < newInnerRect && getPoint.x > 0 && getPoint.y > 0)
					newInnerRect = getPoint;
				
				// берем максимальную или минимальную высоту всех объектов в тайле
				if(newHeight == 0)
				{
					if (objectTile.objectZ > 0)
						newHeight = Math.max(newHeight, objectTile.objectZ);
					else
						newHeight = Math.min(newHeight, objectTile.objectZ);
				}
				else
					newHeight = Math.max(newHeight, objectTile.objectZ);
				// недоступные для мувера направления движения от данного тайла
				newDirectionMask |= createDirectionMask(x, y, objectTile);
				
				if(objectTile.hasBorder)
					updateBorderQueue[index] = true;
			}
			
			mapTile.pathMask = newMask;
			mapTile.topLeft = newInnerRect;
			mapTile.objectZ = newHeight;
			mapTile.directionMask = newDirectionMask;
		}
		
		private function addObjectQueueEngine(obj:IsoObject):void
		{
			if(tilesIsFree(obj.position, obj))
			{
				addObject(obj);
				
				var i:int = addObjectQueue.indexOf(obj);
				
				if(i > -1)
					addObjectQueue.splice(i, 1);
			}
		}
		
		private function createBorders(_index:uint):void
		{
			var _y:int = _index >>> 16;
			var _x:int = _index & 0xFFFF;
			var _xx:int, _yy:int;
			var _checkRect:Rectangle = new Rectangle(0,0,1,1);
			
			for(_yy=_y-1;_yy<=_y+1;_yy++)
			{
				for(_xx=_x-1;_xx<=_x+1;_xx++)
				{
					if(_yy == _y && _xx == _x)
						continue;
					
					_checkRect.x = _xx;
					_checkRect.y = _yy;
					
					if(tilesIsFree(_checkRect))
						pathFindingMap._map[_yy][_xx].pathMask |= MapObjectTiled.TYPE_THRESHOLD;
				}
			}
			
		}
		
		/**
		 * Определение невозможных путей, если объект размером больше одного тайла
		 */		
		private function createDirectionMask(_x:int, _y:int, target:MapObjectTiled):uint {	
			
			var result:uint = 0;	
			// проверка соседних тайлов на наличие объекта
			if(target.position.width > 1 || target.position.height > 1)
			{
				if(_x > 0 && objectsOnTile[_x - 1][_y].indexOf(target) != -1)
					result += MapObjectTiled.RIGHT;
				if(_x < objectsOnTile.length - 1 && objectsOnTile[_x + 1][_y].indexOf(target) != -1)
					result += MapObjectTiled.LEFT;
				if(_y > 0 && objectsOnTile[_x][_y - 1].indexOf(target) != -1)
					result += MapObjectTiled.BOTTOM;
				if(_y < objectsOnTile[_x].length - 1 && objectsOnTile[_x][_y + 1].indexOf(target) != -1)
					result += MapObjectTiled.TOP;
			}
			
			return result;
		}
		
		/**
		 * Обновление информации об одном тайле.
		 */		
		public function refreshReachableTile(index:uint):void {
			
			if(!basicMover || !pathFindingMap)
				return;
			
			var startY:int = index >>> 16;	
			var startX:int = index & 0xFFFF;
						
			var _yy:int, _xx:int;
			var _mWidth:int = pathFindingMap.getWidth();
			var _mHeight:int = pathFindingMap.getHeight();
			var result:Boolean = false;
			
			// первая проверка является ли данный тайл проходимым для нашего призрачного мувера
			// поиск хотя бы одного подхода к данному тайлу
			for(_yy=startY-1;_yy<=startY+1;_yy++)
			{
				for(_xx=startX-1;_xx<=startX+1;_xx++)
				{
					if(!(_xx==startX && _yy==startY) && _xx >= 0 && _yy >= 0 &&
						_xx < _mWidth && _yy < _mHeight)
					{
						basicMover.position.x = _xx;
						basicMover.position.y = _yy;
						
						pathFindingMap._map[startY][startX]["reachableType"] = MapObjectTiled.checkTileIsReachable(
							pathFindingMap._map[startY][startX] as MapPathTile,
							basicMover,
							MapObjectTiled.getDirectionMask(_xx-startX,_yy-startY)
						);
						
						// если тайл хотя бы с одной стороны проходим, дальнейший поиск не нужен
						if(pathFindingMap._map[startY][startX]["reachableType"] > 0)
						{
							result = true;
							break;
						}
					}
				}
				
				if(result)
					break;
			}
			
			needCheckReachableTiles = true;
		}
		
		private var reachableChecked:Object;
		private var reachableQueue:Object;
		/**
		 * Поиск досягаемых тайлов.
		 * @param startX 
		 * @param startY
		 * @param exclude массив с тайлами, которые должны быть исключены
		 * @return 
		 */		
		public function buildReachableMap(startX:int, startY:int, createMap:Boolean=true, 
										  exclude:uint=0, targetTiles:Object=null):Boolean {
			if(!basicMover)
				return true;
			
			reachableChecked = {};
			reachableQueue = {};
			
			var key:String;
			var _x:uint, _y:uint, _xx:uint, _yy:uint;
			var _index:uint;
			var stop:Boolean = false;
			var _mWidth:int = pathFindingMap.getWidth()-1;
			var _mHeight:int = pathFindingMap.getHeight()-1;
			var _startIndex:uint = startX + (startY << 16);
			
			var reachableResult:int;
			
			reachableQueue[_startIndex] = true;
			
			if(createMap)
				pathFindingMap._map[startY][startX]["reachableType"] = 1;
			
			// использование объектов дает большую скорость
			while(true)
			{
				stop = false;
				for (key in reachableQueue)
				{
					delete reachableQueue[key];
					_index = uint(key);
					_y = _index >>> 16;
					_x = _index & 0xFFFF;
					
					for(_yy=((_y==0)?_y:_y-1);_yy<=((_y==_mHeight)?_y:_y+1);_yy++)
					{
						for(_xx=((_x==0)?_x:_x-1);_xx<=((_x==_mWidth)?_x:_x+1);_xx++)
						{
							if((_yy==_y && _xx==_x) || (_yy==_y+1 && _xx==_x-1) || (_yy==_y-1 && _xx==_x+1))
								continue;
							
							_index = _xx + (_yy << 16);
							
							if(_index == exclude || (_xx==_x && _yy==_y) || reachableChecked[_index])
								continue;
							
							reachableResult = int(MapObjectTiled.checkTileIsReachable(
								pathFindingMap._map[_yy][_xx] as MapPathTile,
								basicMover,
								MapObjectTiled.getDirectionMask(_xx-_x, _yy-_y)
							));
							
							if(createMap)
								pathFindingMap._map[_yy][_xx]["reachableType"] = reachableResult;
							
							if(reachableResult == 1)
							{
								reachableQueue[_index] = true;
								reachableChecked[_index] = true;
								
								if(targetTiles && targetTiles[_index])
								{
									delete targetTiles[_index];
									
									stop = false;
									
									for (key in targetTiles)
										stop = true;
									
									if(!stop)
										return true;
								}
							}
						}
					}
					
					stop = true;
					break;
				}
				if(!stop)
					break;
			}
			
			return false;
		}
		
		/**
		 * Метод создает карту доступных для главного героя тайлов.
		 */		
		public function createReachableMap(mover:IsoMover):void {
			
			// заполняем карту объектам, которые были добавлены до мувера, 
			// но еще не были зарегистрированы в pathFindingMap
			var s:String;
			for(s in unregisteredTilesQueue)
				refreshPathTile(uint(s));
			unregisteredTilesQueue = [];
			
			// сохраняем важные нам значения в темпового героя
			basicMover = new IsoMover(new MovieClip());
			basicMover.pWidth = mover.pWidth;
			basicMover.pHeight = mover.pHeight;
			basicMover.searchDirection = mover.searchDirection;
			basicMover.pathMask = mover.pathMask;
			basicMover.maskType = mover.maskType;
			basicMover.objectZ = mover.objectZ;
			basicMover.position = new IsoPoint(mover.position);
			
			// рекурсивная пробежка по всем тайлам, те которые оставились 
			// за кадром помечаются как недоступные
			buildReachableMap(int(basicMover.position.x), int(basicMover.position.y));
			
			checkClosedTiles();
			
			reachableMapInited = true;
		}
		
		private function checkClosedTiles():void {
			
			needCheckReachableTiles = false;
			
			var _x:int, _y:int, _xx:int, _yy:int;
			var _mWidth:int = pathFindingMap.getWidth()-1;
			var _mHeight:int = pathFindingMap.getHeight()-1;
			var l:uint, d:uint, u:uint;
			var _currentIndex:int = 0;
			var _globalIndex:int = 1;
			var islands:Object = {};
			var freeTilesMask:uint;
			var key:String;
			var recVal:int;
			
			IslandsMap = {};
			IslandsMapLinks = {};
			
			// подготовка карты островов
			for(_y=-1;_y<=_mHeight+1;_y++)
			{
				IslandsMap[_y] = {};
				
				for(_x=-1;_x<=_mWidth+1;_x++)
				{
					if(_y>-1 && _x>-1 && _y < _mHeight+1 && _x < _mWidth+1 && 
						pathFindingMap["_map"][_y][_x]["reachableType"] != 0)
					{
						IslandsMap[_y][_x] = 0;
						continue;
					}
					
					l = _x > -1 ? IslandsMap[_y][_x-1] : 0;
					u = _y > -1 ? IslandsMap[_y-1][_x] : 0;
					d = (_x > -1 && _y > -1) ? IslandsMap[_y-1][_x-1] : 0;
					
					_currentIndex = l | u | d;
					
					if(_currentIndex == 0)
						_currentIndex = _globalIndex++;	
					else
					{ 
						_currentIndex = (l==0)?(u==0?d:u):l;
						
						if(l^u && u>0 && l>0 && checkRecursion(u, l))
						{
							recVal = find(IslandsMapLinks[u]);
							
							if(recVal)
							{
								if(recVal^l && checkRecursion(recVal, l))
									IslandsMapLinks[recVal] = l;
							}
							else
								IslandsMapLinks[u] = l;
						}
						
//						if(l^u) 
//							IslandsMapLinks[u] = l;	
					}
					
					IslandsMap[_y][_x] = _currentIndex;	
				}
			}
			
//			function find(index:int):int
//			{
//				return IslandsMapLinks[index] ? IslandsMapLinks[index] == 0 ? index : find(int(IslandsMapLinks[index])) : index;
//			}
			function find(index:int):int
			{
				return IslandsMapLinks[index] ? find(int(IslandsMapLinks[index])) : index;
			}
			
			function checkRecursion(checkValue:int, index:int):Boolean
			{
				return !IslandsMapLinks[index] ? true : ((IslandsMapLinks[index] == checkValue) ? false : checkRecursion(checkValue, IslandsMapLinks[index])); 
			}
			
			// коррекция
			for(_y=-1;_y<=_mHeight+1;_y++)
				for(_x=-1;_x<=_mWidth+1;_x++)
				{
					if(IslandsMap[_y][_x] > 0)
						IslandsMap[_y][_x] = find(IslandsMap[_y][_x]);
				}	
			
			
			// поиск тайлов
			for(_y=0;_y<=_mHeight;_y++)
				for(_x=0;_x<=_mWidth;_x++)
				{
					if(IslandsMap[_y][_x] != 0)
						continue;
					
					islands = {};
					freeTilesMask = 0;
					for(_yy=((_y==-1)?_y:_y-1);_yy<=((_y==_mHeight+1)?_y:_y+1);_yy++)
						for(_xx=((_x==-1)?_x:_x-1);_xx<=((_x==_mWidth+1)?_x:_x+1);_xx++)
						{
							if((_yy==_y && _xx==_x) || (_yy==_y+1 && _xx==_x-1) || (_yy==_y-1 && _xx==_x+1))
								continue;
							
							_currentIndex = _yy<_y?(_xx<_x?1:2):(_yy>_y?(_xx>_x?8:16):(_xx<_x?32:4));
							
							if(IslandsMap[_yy][_xx] > 0)
								islands[IslandsMap[_yy][_xx]] |= _currentIndex;
							else
								freeTilesMask |= _currentIndex;
						}
					
					pathFindingMap["_map"][_y][_x]["reachableType"] = 1;
					
					// по возможностям движения персонажа
					if(!(freeTilesMask & 1 && freeTilesMask & 8) && 
						!(freeTilesMask & 2 && freeTilesMask & 16) && 
						!(freeTilesMask & 4 && freeTilesMask & 32))
						continue;
					
					for(key in islands)
					{
						_currentIndex = islands[key];
						
						if(
							(_currentIndex & 1 && _currentIndex & (4 + 8 + 16)) ||
							(_currentIndex & 8 && _currentIndex & (1 + 2 + 32)) ||
							(_currentIndex & (32 + 16) && _currentIndex & (2 + 4))
							
						)
						{
							pathFindingMap["_map"][_y][_x]["reachableType"] = 2;
							break;
						}
					}
				}
			
			return;
			
			trace("= = = = = = = = = = = = = = = = = = = = ");	
			var str:String;
			for(_y=-1;_y<_mHeight+1;_y++)
			{
				str = "";
				for(_x=-1;_x<_mWidth+1;_x++)
					str += (!IslandsMap[_y][_x] ? "-" : String.fromCharCode(65 + IslandsMap[_y][_x])) + " ";
				trace(str);
			}
			trace("= = = = = = = = = = = = = = = = = = = = ");
		}
				
		override public function unLoad():void{
			// утилизировать тайловый массив
			var i:int; var j:int;
			for(i = 0;i<tiles.length;i++){
				for(j = 0;j<tiles.length;j++){
					TileBase(tiles[i][j]).end();
					objectsOnTile[i][j] = null;
				}
				tiles[i] = null;
				objectsOnTile[i] = null;
			}
			tiles = null;
			objectsOnTile = null;
			pathFindingMap = null;
			
			super.unLoad();
		}
		
		/**
		 * Протрейсить объекты, содержащиеся в objectsOnTile - карта количеств объектов в кажом из тайлов
		 */
		public function printObjectsOnTiles():String{
			var str:String = "	 ";
			var i:int;
			var j:int;
			for(i = 0;i<objectsOnTile.length;i++)
				str += (i < 10?" ":".") + i.toString().substr(-1,1);
			str += "\n	==========================================\n";
			var lines:Array = [];
			
			for(i = 0;i<objectsOnTile.length;i++){
				for(j = 0;j<objectsOnTile[i].length;j++){
					if(lines[j] == null)lines[j] = "";
					var value:String = objectsOnTile[i][j].length == 1?
						String.fromCharCode(MapBase(MapObjectTiled(objectsOnTile[i][j][0]).parentGameObject).isoObjects.indexOf(objectsOnTile[i][j][0]) + 1040)
						:objectsOnTile[i][j].length;
					lines[j] += (value.length == 1?" "+value:"." + value.substr(1));
				}
			}
			
			for(i = 0;i<lines.length;i++)
				str += i + "	|" + lines[i] + "|\n";
			
			str += "	==========================================\n";
			
			trace(str);
			return str;
		}
	}
}