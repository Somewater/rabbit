package com.somewater.rabbit.iso.scene
{
	import com.astar.Astar;
	import com.astar.AstarEvent;
	import com.astar.AstarPath;
	import com.astar.BasicTile;
	import com.astar.Map;
	import com.astar.PathRequest;
	import com.pblabs.engine.PBE;
	import com.pblabs.engine.components.TickedComponent;
	import com.pblabs.engine.core.ITickedObject;
	import com.pblabs.engine.core.ObjectType;
	import com.pblabs.engine.core.ObjectTypeManager;
	import com.pblabs.engine.debug.Logger;
	import com.pblabs.engine.debug.Profiler;
	import com.pblabs.engine.entity.EntityComponent;
	import com.pblabs.rendering2D.BasicSpatialManager2D;
	import com.pblabs.rendering2D.DisplayObjectScene;
	import com.pblabs.rendering2D.ISpatialManager2D;
	import com.pblabs.rendering2D.ISpatialObject2D;
	import com.pblabs.rendering2D.RayHitInfo;
	import com.somewater.rabbit.iso.IsoRenderer;
	import com.somewater.rabbit.iso.IsoSpatial;
	import com.somewater.rabbit.iso.astar.IThinkWall;
	import com.somewater.rabbit.iso.astar.IsoAnalyzer;
	
	import flash.debugger.enterDebugger;
	import flash.events.Event;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.utils.Dictionary;
	
	public class IsoSpatialManager extends TickedComponent implements ISpatialManager2D
	{
		public static const EVENT_SCENE_RESIZE:String = "eventSceneResize";
		
		
		public static var instance:IsoSpatialManager;
		
		/**
		 * Список всех объектов карты, без сортировки, одномерный
		 */
		public var objectList:Array;
		
		/**
		 * Двумерный массив объектов карты вида:
		 * mapSpatial[x][y] == array of objects on tile [x, y]
		 */
		public var mapSpatial:Array;
		
		/**
		 * Карта для pathfinding
		 */
		public var mapPath:Map;
		
		/**
		 * Ассоциативный (!) массив индексов тайлов карты проходимости, ждущих обновления значений
		 * index = y << 16 + x
		 * т.е. отсюда: x = index & 0xFFFF, y = index >>> 16;
		 */
		protected var dirtyPathTiles:Array;
		
		/**
		 * Индекс тайла, который обновляется в данный момент на предмет проходимости
		 */
		public static var dirtyTileIndex:uint;
		
		
		/**
		 * Поиск пути
		 */
		protected var astar:Astar;
		
		/**
		 * Главный и единственный анализатор проходимоти/непроходимости тайлов
		 */
		protected var astarPathAnalyzer:IsoAnalyzer;
		
		public var width:int;
		public var height:int;
		
		public function IsoSpatialManager()
		{
			super();
			
			if(instance)
				throw new Error("Must be only one IsoSpatialManager");
			else
				instance = this;
			
			astar = new Astar();
			astarPathAnalyzer = new IsoAnalyzer();
			astar.addAnalyzer(astarPathAnalyzer);
			
			updatePriority = 1000000;// отрабатывает перед всеми
			objectList = [];
		}
		
		/**
		 * Установить размер, в тайлах
		 */
		public function setSize(w:int, h:int):void
		{
			width = w;
			height = h;
			
			if(mapSpatial == null)
				mapSpatial = [];
			
			dirtyPathTiles = [];			
			
			for(var i:int = 0; i<w; i++)
			{
				var line:Array = mapSpatial[i];
				if(line == null)
				{
					line = [];
					mapSpatial[i] = line;
				}
				for(var j:int = 0;j<h;j++)
				{
					if(line[j] == null)
						line[j] = [];
					dirtyPathTiles[(j << 16) + i] = true;
				}
				if(line.length > h)
					line.length = h;
			}
			if(mapSpatial.length > w)
				mapSpatial.length = w;
				
			if(mapPath == null)
				mapPath = new Map(w, h);
			else
				mapPath.setSize(w, h);
			
			owner.eventDispatcher.dispatchEvent(new Event(IsoSpatialManager.EVENT_SCENE_RESIZE));
		}
		
		override protected function onReset():void
		{
			if(PBE.scene && IsoLayer.instance == null)
			{
				DisplayObjectScene(PBE.scene).layers[10] = new IsoLayer();// на нулевом слое сцены располагаются iso объекты
			}
		}
		
		/**
		 * @inheritDoc
		 */
		public function addSpatialObject(object:ISpatialObject2D):void
		{
			objectList.push(object);
		}
		
		/**
		 * @inheritDoc
		 */
		public function removeSpatialObject(object:ISpatialObject2D):void
		{
			var index:int = objectList.indexOf(object);
			if (index == -1)
			{
				Logger.warn(this, "removeSpatialObject", "The object was not found in this spatial manager.");
				return;
			}
			
			objectList.splice(index, 1);
		}
		
		/**
		 * Determines if the two rectangles intersect.
		 * This, along with the objectMask of the spatial component is used in queryRectangle 
		 * to determine which spatial components are added to the results array.
		 */  
		public function boxVsBox(box1:Rectangle, box2:Rectangle):Boolean
		{
			return box1.intersects(box2);
		}
		
		/**
		 * @inheritDoc
		 */
		public function queryRectangle(box:Rectangle, mask:ObjectType, results:Array):Boolean
		{
			Profiler.enter("QueryRectangle");

			var foundAny:Boolean = false;
			
			var maxX:int = Math.min(width, box.right);
			var maxY:int = Math.min(height, box.bottom);
			
			var added:Dictionary = new Dictionary();// хранит уже добавленные в ответ объекты
			
			var i:int = box.x;
			do
			{
				var j:int = box.y;
				do
				{
					var objects:Array = mapSpatial[i][j];
					
					for(var k:int = 0; k<objects.length; k++)
					{
						var spatial:IsoSpatial = objects[k];
						
						if(added[spatial])
							continue;// уже добавлен в массив result
						
						if(mask && (spatial._objectMask == null
								|| (spatial._objectMask._bits & mask._bits) == 0))
							continue;// не соответствует маске
						
						results.push(spatial);
						added[spatial] = true;
						
						foundAny = true;
					}
				}
				while(++j < maxY)
			}
			while(++i < maxX)
			
			Profiler.exit("QueryRectangle");
			return foundAny;
		}
		
		/**
		 * @inheritDoc
		 */
		public function queryCircle(center:Point, radius:Number, mask:ObjectType, results:Array):Boolean
		{
			Profiler.enter("QueryCircle");

			var foundAny:Boolean = false;
			
			var centerX:int = center.x;
			var centerY:int = center.y;
			
			var minX:int = Math.max(0, centerX - radius);
			var minY:int = Math.max(0, centerY - radius);
				
			var maxX:int = Math.min(width - 1, centerX + radius);
			var maxY:int = Math.min(height - 1, centerY + radius);
			
			var added:Dictionary = new Dictionary();// хранит уже добавленные в ответ объекты
			
			for(var i:int = minX; i<=maxX; i++)
			{
				var dx:Number = Math.abs(centerX - i);
				for(var j:int = minY; j<=maxY; j++)
				{
					var dy:Number = Math.abs(centerY - j);
					
					if(radius * radius < dx * dx + dy * dy)
						continue;
					
					var objects:Array = mapSpatial[i][j];
					
					for(var k:int = 0; k<objects.length; k++)
					{
						var spatial:IsoSpatial = objects[k];
						
						if(added[spatial])
							continue;// уже добавлен в массив result
						
						if(mask && ((spatial._objectMask._bits & mask._bits) == 0))
							continue;// не соответствует маске
						
						results.push(spatial);
						added[spatial] = true;
						foundAny = true;
					}
					
				}
			}
			Profiler.exit("QueryCircle");
			
			return foundAny;
		}
		
		/**
		 * @inheritDoc
		 */
		public function getObjectsUnderPoint(worldPosition:Point, results:Array, mask:ObjectType = null):Boolean
		{
			var objects:Array = mapSpatial[int(worldPosition.x)][int(worldPosition.y)];
			var foundAny:Boolean = false;

			var added:Dictionary = new Dictionary();// хранит уже добавленные в ответ объекты
			
			for(var k:int = 0; k<objects.length; k++)
			{
				var spatial:IsoSpatial = objects[k];

				if(added[spatial])
					continue;// уже добавлен в массив result

				if(mask && (spatial._objectMask == null || (spatial._objectMask._bits & mask._bits) == 0))
					continue;// не соответствует маске
				
				results.push(spatial);
				added[spatial] = true;
				foundAny = true;
			}
			
			return foundAny;
		}
		
		/**
		 * @inheritDoc
		 */
		public function castRay(start:Point, end:Point, mask:ObjectType, result:RayHitInfo):Boolean
		{
			throw new Error("Not implemented");
		}
		
		
		/**
		 * Обновить данные в регистрационных массивах по текущему объекту
		 * 
		 * @param flag произвести особые действия согласно битам флага
		 * 				0х1 не вносить в новое положение (напримре, объект удаляется)
		 * 				0x2 не удалять из старого положения (например, объект 
		 * 					уже удалялся, но у него не инициалиацоонны "-1" значения размеров)
		 */
		public function refreshRegistration(spatial:IsoSpatial, 
						oldX:Number, oldY:Number, oldSizeX:Number, oldSizeY:Number,
						newX:Number, newY:Number, newSizeX:Number, newSizeY:Number, flag:int = 0):void
		{			
			newSizeX += newX;
			newSizeY += newY;
			
			
			newX = int(newX);
			newY = int(newY);
			
			var tempY:int = oldY;
			var tempArray:Array;
			
			if((flag & 0x2) == 0)
			{
				var inited:Boolean = oldSizeX != -1 && oldSizeY != -1 && oldX != int.MIN_VALUE && oldY != int.MIN_VALUE;// размер объекта не <0, значит объект уже был внесен в регистрационные массивы
				
				if(inited)
				{	
					oldSizeX += oldX;
					oldSizeY += oldY;
					oldX = int(oldX);
					oldY = int(oldY);
					do
					{
						oldY = tempY;
						do
						{
							// удалить информацию о spatial в тайле [oldX, oldY]
							tempArray = mapSpatial[oldX][oldY];
							var index:int = tempArray.indexOf(spatial);
							if(index != -1)
								tempArray.splice(index, 1);
							dirtyPathTiles[oldX + (oldY << 16)] = true;
						}while(++oldY < oldSizeY)
					}while(++oldX < oldSizeX);
				}
			}
			
			if((flag & 0x1) == 0)
			{
				tempY = newY;
				
				do
				{
					newY = tempY;
					do
					{
						// добавить информацию о spatial в тайле [newX, newY]
						tempArray = mapSpatial[newX][newY];
						if(tempArray.indexOf(spatial) == -1)
							tempArray.push(spatial);
						dirtyPathTiles[newX + (newY << 16)] = true;
					}while(++newY < newSizeY)
				}while(++newX < newSizeX);
			}
		}
		
		
		override public function onTick(deltaTime:Number):void
		{
			// сначала создаем копию dirtyPathTiles
			var temp:Array = [];
			var index:String;
			for(index in dirtyPathTiles)
				temp[index] = true;
			
			for(index in temp)
			{
				refreshPathTile(parseInt(index));
			}
			
			astar.runCore();
		}
		
		
		/**
		 * @param index = y << 16 + x
		 */
		public function refreshPathTile(index:uint):void
		{
			dirtyTileIndex = index;
			
			var x:int = index & 0xFFFF;
			var y:int = (index >>> 16) & 0xFFFF;
			var tile:BasicTile = mapPath._map[y][x];
			if(tile == null)
			{
				tile = new BasicTile(new Point(x, y));
				mapPath._map[y][x] = tile;
			}
			tile.hook = null;
			var mask:uint = tile.groundMask;
			var objects:Array = mapSpatial[x][y];
			for(var i:int = 0;i<objects.length;i++)
			{
				var isospatial:IsoSpatial = objects[i];
				var occupyMaskRule:int = isospatial.occupyMaskRule
				if(occupyMaskRule == 0)
					mask = mask & (~isospatial.occupyMask);
				else if(occupyMaskRule == 1)
					mask = mask & (~IThinkWall(isospatial).getOccupyMask(x, y));
				else if(occupyMaskRule == 2)
				{
					tile.hook = IThinkWall(isospatial).hook;
					break;
				}
				else
					throw new Error("Undefined occupy mask rule index = " + occupyMaskRule);
			}
			
			tile.mask = mask;
			
			delete dirtyPathTiles[index];
		}
		
		
		public function pointIsFree(x:int, y:int):Boolean
		{
			if(x < 0 || x >= width || y < 0 || y >= height)
				return false;// точка за пределами поля
			var tile:BasicTile = getPathTile(x, y);
			return tile.mask == tile.groundMask && tile.hook == null;
		}
		
		protected function getPathTile(x:int, y:int):BasicTile
		{
			var tile:BasicTile = mapPath._map[y][x];
			if(tile)
				return tile;
			refreshPathTile(x + (y << 16));
			return mapPath._map[y][x];
		}
		
		
		
		/**
		 * Находится ли искомая точка в пределах размеров игрового поля
		 */
		public static function contain(point:Point):Boolean
		{
			return (point.x >= 0 && point.y >= 0 && point.x  < instance.width && point.y < instance.height);
		}
		
		
		
		/**
		 * Придать точке, приходящей извне (в методы set position, set destination)
		 * значение, учитывая размер (прибавить по 0.5 тайла, чтобы персонажи
		 * располагались посередине тайлов)
		 */
		public static function centrePosition(position:Point, size:Point):Point
		{
			position.x += size.x < 1?(1 - size.x) * 0.5:0;
			position.y += size.y < 1?(1 - size.y) * 0.5:0;
			return position;
		}
		
		
		
		/**
		 * Добавить запрос на поиск пути в очередь
		 */
		public static function requestPath(start:Point, end:Point, spatial:IsoSpatial, directionMask:int, callback:Function):void
		{
			var request:PathRequest = new PathRequest(start, end, instance.mapPath, spatial, callback, directionMask);
			var endBasicTile:BasicTile = instance.mapPath.getTileAt(end)
			
			// hook на случай запроса точки вне карты
			if(end.x >= instance.width || end.y >= instance.height || end.x < 0 || end.y < 0 ||
				// hook на случай, если end непроходим (и не управляется хуком, 
				// а значит на начальном этапе нельзя знать, проходим он или нет)
				(endBasicTile.hook == null && (endBasicTile.mask & spatial.passMask) != spatial.passMask))
			{
				callback(new AstarEvent(AstarEvent.PATH_NOT_FOUND, null, request));
				return;
			}

			// hook на случай, если start-end соседние точки
			var dx:Number = start.x - end.x;
			dx = dx>0?dx:-dx;
			var dy:Number = start.y - end.y;
			var dy_sig:Number = dy
			dy = dy>0?dy:-dy;
			if(
				(dx == 0 && dy == 0) // если start и end одна и та же точка 
				||
				(directionMask == -4 && 
				(
					// direction == -4
					(dx == 1 && dy == 1)// если перемещение по диагонали
					||
					(dy_sig < 0)// если перемещение вниз
				)) 
				||
				(
					// direction != -4
					((dx == 1 && dy ==0) || (dy == 1 && dx ==0)) 
					||
					(dx == 1 && dy ==1 && (directionMask == 8))
				)
			  )
			{
				var analyze:Boolean = analyzeTile(end, spatial, start);
				callback(new AstarEvent(analyze?AstarEvent.PATH_FOUND:AstarEvent.PATH_NOT_FOUND, 
					analyze?new AstarPath([instance.mapPath.getTileAt(start),endBasicTile]):null, request));
				return;
			}

			instance.astar.getPath(request);
		}
		
		/**
		 * Провести проверку одного тайла на проходимость
		 * (ожидается, что тестируется соседний тайл, относительно персонажа
		 * т.к. именно по этому алгоритму вычисляется direction перемещения
		 * через тайл, если оно требуется)
		 * @return тайл свободен (для данного персонажа при данных условиях)
		 */
		public static function analyzeTile(tile:Point, spatial:IsoSpatial, startTile:Point):Boolean
		{
			// проверить соответствие
			// c IsoAnalyzer.analyzeTile
			var basicTile:BasicTile = instance.mapPath.getTileAt(tile);
			if(basicTile.hook != null)
				return basicTile.hook(basicTile, spatial, startTile);
			else
				return (basicTile.mask & spatial.passMask) == spatial.passMask;
		}

		public static function globalToIso(global:Point):Point {
			var scenePos:Point = PBE.scene.position;
			global.x -= scenePos.x;
			global.y -= scenePos.y;
			return IsoRenderer.screenToIso(global);
		}
	}
}