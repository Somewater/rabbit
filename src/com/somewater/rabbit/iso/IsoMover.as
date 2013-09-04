package com.somewater.rabbit.iso
{
	import com.astar.AstarEvent;
	import com.astar.BasicTile;
	import com.pblabs.engine.PBE;
	import com.pblabs.engine.components.TickedComponent;
	import com.pblabs.engine.entity.PropertyReference;
	import com.somewater.rabbit.States;
	import com.somewater.rabbit.iso.scene.IsoSpatialManager;
	import com.somewater.rabbit.util.RandomizeUtil;
	
	import flash.debugger.enterDebugger;
	import flash.events.Event;
	import flash.geom.Point;
	
	/**
	 * Управляет перемещением объекта в точку, заданную свойством destination
	 */
	public class IsoMover extends TickedComponent
	{
		public static const DESTINATION_SUCCESS:String = "destinationSuccess";
		public static const DESTINATION_ERROR:String = "destinationError";
		public static const TILE_CHANGED:String = "tileChanged";
		public static const TILE_REACHED:String = "tileReached";
		public static const DESTINATION_CHANGED:String = "destinationChanged";
		public static const MOVING_STARTED:String = "movingStarted";
		
		public static const SIGNAL_TILE_CHANGED:String = "signal.tileChanged";
		
		public static const DEST_TYPE_MOUSE:String = 'mouse';
		public static const DEST_TYPE_KEY:String = 'key';
		
		private var tempOffsetPos:Point = new Point();// точка для осуществления смены свойства position без создания нового экземпляра точки
		
		/**
		 * Куда пытается двигаться персонаж. null если никуда (в т.ч. обнулять, если не удалось дойти)
		 */
		protected var _destination:Point;
		public var destinationType:String;
		protected var _destinationPath:Array;// массив последовательных точек от position до destination (ответ astar)
		
		/**
		 * destination, приведенная к ближайщему тайлу (т.е. имеет ровыне координаты x, y)
		 */
		private var _roundDestination:Point;
		
		
		/**
		 * Скорость персонажа, тайлов в секунду
		 */
		protected var _speed:Number = 1;
		
		
		/**
		 * Ссылка на @Spatial
		 */
		protected var _spatial:IsoSpatial;
		private var _render:IsoRenderer;
		public var directionMask:int;
		
		/**
		 * Сколько секунд ожидает персонаж, когда занят тайл перед тем, 
		 * как предпринять новое действие 
		 * (напр, сделать новый запрос пути в астар или отказаться от destination)
		 */
		public var patience:Number = 2;
		
		/**
		 * Сколько секунд персонаж еще будет стоять
		 */
		public var currentPatience:Number;
		
		/**
		 * Если != 0, означает, что объект ждет: освобождения тайла (1) или ответа от астара (2)
		 */
		public var patienceMode:int;
		
		/**
		 * Сколько запросов к астару пошлет персонаж, перед тем 
		 * как понять, что цель недостижима (первый запрос к астару в счете не учитывается)
		 */
		public var maxAstarRequests:int = 5;
		
		/**
		 * Сколько запросов к астару послано на данный момент
		 */
		public var currentAstarRequestNum:int;
		
		/**
		 * Флаг, означающий, что происходит установка нового значения destination
		 * (любые другие попытки его установки игнорируются)
		 */
		private var destinationExchange:Boolean = false;

		/**
		 * Флаг прерывает выполнение функции onTick
		 */
		public var paused:Boolean = false;
		
		public function IsoMover()
		{
			super();
			
			initiateVars();
		}
		
		
		/**
		 * Послать персонаж к заданной точке и установить колбэки на достижение точки и неудачу
		 */
		protected var onDestinatedSuccess:Function;// callback();
		protected var onDestinatedError:Function;
		private var clearCallbacksFlag:Boolean = true;
		public function setDestination(value:Point, onSuccess:Function, onError:Function = null):void
		{
			if(onDestinatedError != null && onError != onDestinatedError)// если новые колбэк onerror не совпадает со старым, вызываем старый
				dispatchDestination(false);
			
			onDestinatedSuccess = onSuccess;
			onDestinatedError = onError;
			
			clearCallbacksFlag = false;
			destination = value;
			clearCallbacksFlag = true;
		}
		
		/**
		 * Установить новую точку следования персонажа. 
		 * Если была старая, персонаж перестает к ней двигаться
		 * Если задана value=NULL, персонаж останавливается на месте
		 */
		public function set destination(value:Point):void
		{
			CONFIG::debug
			{
				if(value && (int(value.x) != value.x || int(value.y) != value.y))
					throw new Error("Unsharpen destination position: " + value);
			}
			
			if(destinationExchange || (_destination && value && _destination.equals(value))) return;
			destinationExchange = true;
			
			_destination = value;
			
			_destinationPath = null;
			
			if(_spatial == null)
				_spatial = owner.getProperty(new PropertyReference("@Spatial"));
			
			if(directionMask == -1)
			{
				directionMask = owner.getProperty(new PropertyReference("@Render.useDirection"), -1);
			}
			
			currentPatience = 0;
			currentAstarRequestNum = 0;
			if(_destination && clearCallbacksFlag)
			{
				dispatchDestination(false);// уведомить, что ранее определенная destination не будет достигнута
			}else
				owner.eventDispatcher.dispatchEvent(new Event(IsoMover.DESTINATION_CHANGED));
			destinationExchange = false;
			
			if(_destination)
			{
				owner.setProperty(new PropertyReference("@Render.state"), States.WALK);
				
				_roundDestination.x = int(_destination.x);
				if(_roundDestination.x >= IsoSpatialManager.instance.width)
					_roundDestination.x = IsoSpatialManager.instance.width - 1;
				
				_roundDestination.y = int(_destination.y);
				if(_roundDestination.y >= IsoSpatialManager.instance.height)
					_roundDestination.y = IsoSpatialManager.instance.height - 1;
				
				IsoSpatialManager.requestPath(_spatial.tile, _roundDestination, _spatial, directionMask, onPathFound);
			}
		}
		
		
		protected function onPathFound(event:AstarEvent):void
		{
			patienceMode = 0;// прекратить любое ожидание и попробовать двигаться по новому пути
			
			if(event.type == AstarEvent.PATH_FOUND)
			{
				currentAstarRequestNum++;
				_destinationPath = event.path._path;
				
				// "отсерединить" фактические точки пути
				var length:int = _destinationPath.length;
				var s:Point = _spatial.size;
				for(var i:int = 0;i<length;i++)
				{
					var tile:BasicTile = BasicTile(_destinationPath[i]);
					var position:Point = tile.position.clone();
					
					// если это последняя точка пути, списать ее координаты с фактической точки _destination
					// для частного случая, когда destiination неровная точка, это позвоит "не потерять" ее неровность
					if(i == (length - 1) && (int(_destination.x) != _destination.x || int(_destination.y) != _destination.y))
					{
						position.x = _destination.x;
						position.y = _destination.y;
					}
					else
						IsoSpatialManager.centrePosition(position, s)
					
					_destinationPath[i] = new PathItem(tile, position);
				}
				checkFirstPathPoint();
				if(_destinationPath.length > 0)
					_owner._eventDispatcher.dispatchEvent(new Event(MOVING_STARTED))
			}else{
				_destination = null;
				setRenderState(false);
				
				dispatchDestination(false);
			}
		}

		/**
		 * Проверить, не лежит ли текущая позиция мувера на линии между первой и второй точкой пути
		 * Если да, то первую точку пути можно вырезать за ненадобностью
		 */
		protected function checkFirstPathPoint():void
		{
			if(_destinationPath.length > 1)
			{
				var p1:Point = PathItem(_destinationPath[0]).position;
				var p2:Point = PathItem(_destinationPath[1]).position;
				var p:Point = _spatial.position;
				// если текущая позиция мувера лежит на линии между первой и второй точкой пути, вырезать первую точку пути и идти сразу ко второй
				if(p1 && p2 && ((p.x == p1.x && p1.x == p2.x) || (p.y == p1.y && p1.y == p2.y) ||
					((p1.x - p.x)/(p1.y - p.y) == (p2.x - p.x)/(p2.y - p.y))
						))
					_destinationPath.shift();
			}
		}
		
		
		public function get destination():Point
		{
			return _destination;
		}
		
		
		public function get destinationPath():Array
		{
			return _destinationPath?_destinationPath:[];
		}
		
		
		public function set speed(value:Number):void
		{
			_speed = value;
		}
		
		public function get speed():Number
		{
			return _speed;
		}
		
		
		
		override public function onTick(deltaTime:Number):void
		{
			if(paused)
				return;

			if(patienceMode)
			{
				currentPatience -= deltaTime;
				if(!nextTileDestinated())// если песонаж ждет, то очевидно что он стоит перед сменой тайлов
				{	
					return;
				}
			}
			
			var item:PathItem = _destination && _destinationPath?(_destinationPath[0]):null;
			
			if(item == null)
				return;
			
			if(_spatial == null)
				_spatial = owner.getProperty(new PropertyReference("@Spatial"));
			
			var nextPoint:Point = item.position;
			var _position:Point = _spatial._position;
			var dx:Number = (nextPoint.x - _position.x);
			var dy:Number = (nextPoint.y - _position.y);
			
			//trace(patienceMode + "	pos=" + _position + "	np=" + item.position + "	dest=" + _destination);
			
			
			var $speed:Number = _speed * deltaTime;
			
			var ratio:Number = ($speed * $speed) / (dx * dx + dy * dy);
			
			if(ratio < 0.999)// KLUDGE только если необходимо существенно уменьшить dx,dy
			{
				ratio = Math.sqrt(ratio);
				dx *= ratio;
				dy *= ratio;
			}
			
			tempOffsetPos.x = _position.x + dx;
			tempOffsetPos.y = _position.y + dy;
			
			var newTileFlag:Boolean = false;
			
			// блок проверки на пересечения с другими муверами
			var _size:Point = _spatial._size;
			var esp:Number = 0.000001;// применяется чтобы координата правого нижнего угла "9"считалась как лежащая в тайле "8"
			if(int(_position.x) != int(tempOffsetPos.x) 
				|| int(_position.y) != int(tempOffsetPos.y) 				
				|| (_size.length// если размер и шаг приведет к "залезанию" верхнего правого угла в новый тайл
							&& (int(tempOffsetPos.x + _size.x - esp) != int(_position.x + _size.x - esp) || 
								int(tempOffsetPos.y + _size.y - esp) != int(_position.y + _size.y - esp))))// если шаг приведет к смене тайла
			{
				newTileFlag = true;
					
				if(!nextTileDestinated())
				{
					return;
				}
			}
			
			_spatial.position = tempOffsetPos;
			
			setRenderState(true);
			
			if(newTileFlag)
			{
				owner.eventDispatcher.dispatchEvent(new Event(IsoMover.TILE_CHANGED));
				owner.signal(SIGNAL_TILE_CHANGED);
			}
			
			if(tempOffsetPos.x == nextPoint.x && tempOffsetPos.y == nextPoint.y)
				nextPointDestinated();
		}
		
		
		
		/**
		 * Очередная точка массива _destinnationPath достигнута
		 * Вставить в очередь следующую или сигнализировать о завершении перемещения
		 */
		protected function nextPointDestinated():void
		{
			// делаем проверку на не null, т.к. после диспатча эвента может произойти требование остановить мувера
			// соответственно, destinationPath обнулится
			if(_destinationPath)
			{
				PathItem(_destinationPath.shift()).clear();
				
				owner.eventDispatcher.dispatchEvent(new Event(IsoMover.TILE_REACHED));
				
				// и еще раз проверяем на null по вышеописанной причине
				if(_destinationPath && _destinationPath.length == 0)
				{
					_destination = null;
					setRenderState(false);
					
					dispatchDestination(true);
				}
			}
		}
		
		
		/**
		 * Достигнута граница соседнего тайла - следующий шаг приведет к смене тайлов, которые занимает объект
		 * @return следующий тайл проходим
		 */
		protected function nextTileDestinated():Boolean
		{
			if(patienceMode == 2 || !_destinationPath) return false;// если ждем ответа от астара, то не делаем проверок
			
			// проверить, проходим ли следующий тайл
			// HARDCODE: проходимость/непроходимость тайла заключена в ф-ции IsoSpatialManager.analyzeTile()
			// для объектов размером более 1 тайла приведет к багу: объект "сам себе" будет блочить тайлы - 
			// для анализа нужно будет применять полный алгоритм анализа тайлов
			// Кроме того, для подобных муверов нужен совокупный анализ тайлов: включая текущий, IsoAnalyzer.analyze
			var item:PathItem = _destinationPath[0];
			var tile:BasicTile = item.tile;
			
			// HOOK, не допустить перепроверки тайла, который был помечан как занятый текущим объектом
			if(patienceMode == 0 && item.marked)
				return true;

			if(IsoSpatialManager.analyzeTile(tile.position, _spatial, _spatial.tile)) // комплексная проверка тайла, включая хуки
			//if((tile.mask & _spatial.passMask) == _spatial.passMask)
			{
				// следующий тайл пути проходим, блочим его
				tile.mask = tile.mask | _spatial.occupyMask;
				item.marked = true;
				currentAstarRequestNum = 0;
				patienceMode = 0;// чтобы не сработал hook
				return true;
			}else if(patienceMode == 0)// если не ждем, инициализировать ожидание
			{
				// следующий тайл пути непроходим, стоим и ждем некоторое время
				setRenderState(false);
				
				currentPatience = patience;
				patienceMode = 1;
				return false;
			}
			
			if(patienceMode && currentPatience <= 0)// если период ожидания превысил предел
			{
				if(currentAstarRequestNum < maxAstarRequests)
				{
					// опросить астар
					// TODO: применяется режим "неэкономных" запросов к астар, можно было бы уточнить часть пути
					patienceMode = 2;
					IsoSpatialManager.requestPath(_spatial.tile, _roundDestination, _spatial, directionMask, onPathFound);
				}else{
					// дойти невозможно
					
					dispatchDestination(false);
				}
			}
			
			return false;
		}
		
		
		private function dispatchDestination(success:Boolean):void
		{
			var callback:Function = success?onDestinatedSuccess:onDestinatedError;
			if(clearCallbacksFlag)
			{
				onDestinatedSuccess = null;
				onDestinatedError = null;
			}
			owner.eventDispatcher.dispatchEvent(new Event(success?DESTINATION_SUCCESS:DESTINATION_ERROR));
			owner.eventDispatcher.dispatchEvent(new Event(IsoMover.DESTINATION_CHANGED));
			callback && callback();
		}
		
		
		/**
		 * Установить начальные значения всех переменных
		 */
		protected function initiateVars():void
		{
			_destination = null;
			_destinationPath = null;
			_spatial = null;
			_render = null;
			directionMask = -1;
			currentAstarRequestNum = 0;
			currentPatience = 0;
			patienceMode = 0;
			
			_roundDestination = new Point();
		}
		
		
		override protected function onRemove():void
		{
			initiateVars();
			if(_destination)
				owner.eventDispatcher.dispatchEvent(new Event(IsoMover.DESTINATION_CHANGED));// мы ее уже не достигнем :(
			super.onRemove();
		}
		
		
		/**
		 * Переставить стейт рендера
		 */
		private function setRenderState(walk:Boolean):void
		{
			if(_render == null)
				_render = owner.lookupComponentByName("Render") as IsoRenderer;
			
			if(_render)
			{
				if(walk && _render.state == States.STAND)
					_render.state = States.WALK;
				else if(!walk && _render.state == States.WALK)
					_render.state = States.STAND;
			}
		}
		
	}
}
