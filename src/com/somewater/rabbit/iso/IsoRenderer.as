package com.somewater.rabbit.iso
{
	import com.pblabs.engine.PBE;
	import com.pblabs.engine.PBUtil;
	import com.pblabs.engine.debug.Logger;
	import com.pblabs.engine.entity.PropertyReference;
	import com.pblabs.rendering2D.DisplayObjectRenderer;
	import com.somewater.rabbit.States;
	import com.somewater.rabbit.storage.Config;
	import com.somewater.rabbit.storage.Lib;
	
	import flash.debugger.enterDebugger;
	import flash.display.DisplayObject;
	import flash.display.MovieClip;
	import flash.events.Event;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	/**
	 * Компонент отвечает за отображение изомеьрических, анимированных персонажей игры
	 * Должен создаваться ПЕРЕД Spatial (желательно самым первым)
	 */
	public class IsoRenderer extends DisplayObjectRenderer
	{
		/**
		 * Размер тайла в пикселах по ширине (X) и по высоте (Y)
		 */
		public static const TILE_SIZE_X:int = Config.TILE_WIDTH;
		public static const TILE_SIZE_Y:int = Config.TILE_HEIGHT;
		
		// прочие константы
		public static const ISO_ANGLE:Number = Math.atan(0.5);// 26.565o угол при изометрии 2.5D, которая применяется в игре
		public static const ISO_ANGLE_TAN:Number = Math.tan(ISO_ANGLE);// 0.5
		public static const ISO_ANGLE_SIN:Number = Math.sin(ISO_ANGLE);// 0.447
		public static const DIV_ISO_ANGLE_SIN:Number = 1/ISO_ANGLE_SIN;
		public static const ISO_ANGLE_COS:Number = Math.cos(ISO_ANGLE);// 0.894
		public static const DIV_ISO_ANGLE_COS:Number = 1/ISO_ANGLE_COS;
		
		public static const BOTTOM:int = 8;
		public static const TOP:int = 4;		
		public static const RIGHT:int = 1;
		public static const LEFT:int = 2;

		public static const PRESICION:Number = 0.1;// величина (в пикселях) смещение персонажа на которую не меняет его direction
		
		public static const TOP_LEFT:int = TOP | LEFT;
		public static const TOP_RIGHT:int = TOP | RIGHT;
		public static const BOTTOM_LEFT:int = BOTTOM | LEFT;
		public static const BOTTOM_RIGHT:int = BOTTOM | RIGHT;
		
		/**
		 * Константы и переменнные, отвечающие за нужный угол поворота персонажа при движении под произвольным углом
		 */	
		protected var _halfAngle:Number = Math.PI;
		protected var _halfTan:Number = Math.tan(Math.PI);
		
		/**
		 * Framerate for playback. 
		 */
		public var frameRate:Number = Config.FRAME_RATE;
		
		
		public var stateToIndex:Array = [];

		/**
		 * Смещение в результате того, что объект имеет не точечный размер
		 * (смещение измеряется в тайлах, как и размер объекта)
		 */
		protected var _sizePositionOffsetValue:Point = new Point();
		protected var _sizePositionOffset:Boolean = false;// true если размер объекта не точечный

		private var lastAppliedPositionOffsetScreen:Point = new Point();
		private var positionOffsetScreen:Point = new Point();
		
		/**
		 * TODO: сделать сеттером, который не позволяет установить стейт,
		 * не существующий в анимационной линейке
		 */
		public var state:String = States.STAND;
		
		private var __direction:uint = 1;// начальное значение - по умолчанию у вновь появившегося объекта
		
		/**
		 * Высота объекта, учитываемая при сортировке z-индексов
		 * Например, скамейка должна правильно сортироваться с окружающим ее объектами,
		 * но если кто-либо находится "внутри" скамейки, то он должен быть выше нее
		 */
		public var correctX:Number = 0;
		public var correctY:Number = 0;

		public var _clip:MovieClip;
		
		public function set direction(value:int):void
		{
			if(value == 0)
				throw new Error("Zero direction don`t allowed!");
			
			if(_useDirection == 8)
			{
				if(value > 2)
					value -= (value > 6?2:1);
			}else if(_useDirection == 4)
			{
				if(value > 2) 
					value = (value == 4?3:4);
			}
			
			__direction = value;
		}
		public function get direction():int
		{
			if(_useDirection == 8)
			{
				return (__direction < 3?__direction:(__direction > 5?	__direction+2:	__direction+1	));
			}else if(_useDirection == 4)
			{
				return __direction > 2?(__direction == 3?4:3):__direction;
			}else{
				return __direction;
			}
		}
		
		
		
		private var tempIsoScreenPoint:Point = new Point();
		//private var currentTempIsoScreenPoint:Point = new Point();// тоже самое, что displayObject.x,displayObject.y (но без погрешности)

		/**
		 * Уже выставленные (в т.ч. в мувиклипе) свойства анимации
		 * Стремятся к значениям, выставленным в state и direction
		 */
		protected var _currentState:String = "empty";
		protected var _currentDirection:int;
		protected var _currentFrameMax:int;
		protected var _currentFrame:int;
		
		/**
		 * аккумулирует дробные кол-ва кадров, на которые стоило передвинуть анимацию
		 * измеряется в кол-ве кадров
		 */
		protected var _timeAccumulator:Number = 0;
		
		/**
		 * вложенный клип второго уровня (frame of stateClip)
		 * содержит визуальную линейку анимации, соответствующую заданному стейту, заданному направлению
		 */
		protected var directionClip:MovieClip;
		
		/**
		 * Момент последнего обновления кадра анимации, в миллисекундан считая со старта флешки
		 * ( = PBE.virtualTime в момент присвоения)
		 */
		protected var _clipLastUpdate:Number = 0;
		
		/**
		 * Флаг необходимости вызвать функцию onClipAdded
		 * после того как новый клип вставлен в компонент
		 */
		protected var _clipDirty:Boolean = true;
		
		/**
		 * Имя клипа, который должен примеряться для создания визуального представления
		 * персонажа
		 */
		public var slug:String = null;
		
		/**
		 * Флаг, содержащий число используемых в клипе direction-ов,
		 * 1 (без направлений, 0 быть не может)
		 * 4
		 * -4 (только 4 направления, только по диагоналям)
		 * 8
		 */
		protected var _useDirection:int = 1;
		
		/**
		 * Флаг, означающий, что объект уже был правильно отсортирован по z-индексу
		 */
		public var zIndexSorted:Boolean = true;
		
		
		/**
		 * Флаг, отключающий отображение элемента на сцене
		 * (равно как и работу рендера)
		 */
		protected var _visible:Boolean = true;
		
		CONFIG::debug
		{
			public function get currentDirection():int{return _currentDirection;}
			public function get currentState():String{return _currentState;}
		}
		
		public function IsoRenderer()
		{
			super();
			
			_size = new Point();
		}
		
		public function set clip(value:MovieClip):void
		{
			if (value === displayObject)
				return;
			
			var labels:Array = value.currentLabels;
			stateToIndex = [];
			for(var i:int = 0;i<labels.length;i++)
			{
				stateToIndex[labels[i].name] = labels[i].frame;
				if(i == 0)
					state = labels[i].name
			}

			_clip = value;
			displayObject = value;
			_clipDirty = true;
		}
		
		/*public function get clip():MovieClip
		{
			return _displayObject as MovieClip;
		}*/
		
		
		
		public function set visible(value:Boolean):void
		{
			if(_visible == value)
				return;
			
			_visible = value;
			
			if(value)
				addToScene();
			else
				removeFromScene();
		}
		
		
		public function get visible():Boolean
		{
			return _visible;
		}
		
		
		
		override public function onFrame(elapsed:Number):void
		{
			if(_visible == false)
				return;
			
			if(!_displayObject)
			{
				if(slug)
					clip = Lib.createMC(slug);
			}
			
			if(_clipDirty)
			{
				// проинициировать все свойства, т.к. кип компонента был заменен (или впервые добавлен)
				onClipAdded(_clip);
				onClipInited(_clip);
				_clipDirty = false;
			}

			// клип имеет право передвинуть анимацию 
			// ("+1" чтобы из за округлений не получалось 33 и 33.3 и анимация не двигалась, хотя и должна)
			var frameTime:Boolean = PBE.processManager.virtualTime - _clipLastUpdate + 1 >= 1000/frameRate;

			if(state == _currentState && (!_useDirection || __direction == _currentDirection))
			{
				if(_currentFrameMax > 1 && frameTime)
				{
					updateFrame((PBE.processManager.virtualTime - _clipLastUpdate) * 0.001 * frameRate);
					_clipLastUpdate = PBE.processManager.virtualTime;
				}
			}
			else if(_useDirection && state == _currentState && __direction != _currentDirection && _currentDirection  != -1)
			{
				updareStateAndDirection();
			}
			else if(state != _currentState && _currentState)
			{
				updareStateAndDirection();
			}
						
			if (_transformDirty)
                updateTransform();
		}
		
		public function set useDirection(value:int):void
		{
			if(_useDirection != value)
			{
				_useDirection = value;
				_halfAngle = Math.abs(Math.PI / value);
				_halfTan = Math.abs(Math.tan(_halfAngle));
			}
		}
		
		public function get useDirection():int
		{
			return _useDirection;
		}
		
		
		public function updareStateAndDirection():void
		{
			_clip.removeEventListener("frameConstructed", onFrameConstructed);
			_clip.addEventListener("frameConstructed", onFrameConstructed);
			
			directionClip = null;
			_currentState = null;
			_currentDirection = -1;			
			_currentFrameMax = -1;
			_currentFrame = -1;
			
			// для изюавления от глюка при изменении state, direction до отработки ф-ции
			var wishState:String = state;
			var wishDirection:int = __direction;
			
			var frameIndex:* = stateToIndex[state];
			if(frameIndex == null)
			{
				throw new Error('Undefined state "' + state + '"');
			}
			if(_useDirection != 1)
				frameIndex = frameIndex + __direction - 1;
			// KLUDGE: -1 т.к.  __direction >= 1 (таков принцип вычисления), 
			// а frameIndex уже содержит начальный кадр (frameIndex>=1)
			
			_clip.gotoAndStop(frameIndex);
			function onFrameConstructed(e:Event):void
			{
				e.currentTarget.removeEventListener(e.type, arguments.callee);
				directionClip = usePseudoMc(e.currentTarget.getChildAt(0));
				directionClip.stop();
				_currentState = wishState;
				_currentDirection = wishDirection;
				_currentFrame = 0;
				_currentFrameMax = directionClip.totalFrames;
			}
		}
		
		
		/**
		 * Обеспечивает возможность не делать кадры direction для персонажей, которые их не имеют
		 * а вместо них помещать само изображение персонажа в нужном стейте
		 */
		protected function usePseudoMc(child:DisplayObject):MovieClip
		{
			var mc:MovieClip =  child as MovieClip;
			if(mc)
				return mc;
			mc = new MovieClip();
			child.parent.addChildAt(mc, child.parent.getChildIndex(child));
			mc.addChild(child);
			return mc;
		}
		
		
		
		/**
		 * 
		 * @param inc на сколько кадров передвинуть линейку анимации
		 * 
		 */
		public function updateFrame(inc:Number):void
		{
			_timeAccumulator = _timeAccumulator + inc;
			var incInt:int = _timeAccumulator;
			_timeAccumulator = _timeAccumulator - incInt;
			if(incInt)
			{
				// переcтавляем на "1" (на следующий) кадр, даже если incInt > 1. 
				// Иначе пропускаются кадры в коротких анимациях, что приводит (для коротких анимаций) к глюкам
				// TODO: исходя из вышеописанного, может быть по разному обрабатывать короткие и длинные анимации?
				_currentFrame = (_currentFrame + 1/*incInt*/) % _currentFrameMax;
				directionClip.gotoAndStop(_currentFrame + 1);
				
				// TODO: не самай элегантный способ заставить кролика "прыжками" перемещаться по экрану
				//var newSpeed:Number = (_currentFrameMax > 1? (_currentFrame / (_currentFrameMax - 1) * 2) : 1) * 3 + 2;
				//owner.setProperty(new PropertyReference("@Spatial.speed"), newSpeed);
			}
		}

		
		
		override public function set position(value:Point):void
		{
			var posX:Number = value.x;
			var posY:Number = value.y;
			
			if (posX == _position.x && posY == _position.y)
				return;
			
			_position.x = posX;
			_position.y = posY;
			_transformDirty = true;
		}
		
		/**
		 * Установить точку, передом к которой надо "смотреть"
		 * (т.е. развернуться к ней преедом)
		 */
		public function set viewPoint(value:Point):void
		{
			//value.x = value.x + _positionOffset.x;
			//value.y = value.y + _positionOffset.y;
			isoToScreen(value);	
			
			__direction = pointToDirection(value.x - _displayObject.x, value.y - _displayObject.y);
		}
		
		protected function pointToDirection(dx:Number, dy:Number):int
		{
			if(_useDirection == 1) return 1;
			if(dx < PRESICION && dx > -PRESICION) dx = 0;
			if(dy < PRESICION && dy > -PRESICION) dy = 0;
			if(dx == 0 && dy == 0){return __direction;}// KLUDGE если новый position совпадает с текущим
			
			var tanX:Number = dy?dx / dy:int.MAX_VALUE * dx;
			var tanY:Number = dx?dy / dx:int.MAX_VALUE * dy;
			
			tanX = tanX < 0?-tanX:tanX;			
			tanY = tanY < 0?-tanY:tanY;
						
			var direct:int = 1;
			if(_useDirection == 4)				
			{
				// если движение по диагонали, то выбираем вертикальные виды
				direct = (tanY < _halfTan?0:(dy<0?TOP:BOTTOM)) || (tanX < _halfTan?0:(dx<0?LEFT:RIGHT));
				//1 ->1, 2 ->2, 4 ->3, 8->4
				//direction = Math.log(direction)/Math.LN2 + 1;
				if(direct > 2) direct = (direct == 4?3:4);
			}else if(_useDirection == -4)
			{
				// самый легкий вариант, сравнения tan посути не нужны
				direct = (dy > 0 ? (BOTTOM | (tanX < _halfTan?0:(dx<0?LEFT:RIGHT))) 
					      : (TOP | (dx < 0? LEFT : RIGHT)) ) - 4;// самый легкий вариант (4 - наименьшее число 5 - 4=>1)
				//5 ->1, 6 ->2, 9 ->4, 10->5, 8->3   (на этом этапе, опсле вычитания (-4)   1 ->1, 2 ->2, 5 ->4, 6->4, 4->3)
				if(direct > 2) direct -= 1;// 1 TR, 2 TL, 3B, 4 BR, 5 BL
			}else if(_useDirection == 8)
			{
				direct = (tanX < _halfTan?0:(dx<0?LEFT:RIGHT)) + (tanY < _halfTan?0:(dy<0?TOP:BOTTOM));
				// избавиться от пустых 3, 7
				if(direct > 2)
					direct -= (direct > 6?2:1);
			}
			else
				Logger.warn(this, "pointToDirection", "Undefined 'useDirection' value " + _useDirection);
			
			if(direct == 0)
				return __direction;
			
			return direct;
		}
		
		
		override public function set size(value:Point):void
		{
			_size.x = value.x;
			_size.y = value.y;
			
			// HARDCODE: чтобы где то еще использовать positionOffser тут надо делать += а не =
			_sizePositionOffsetValue.x = value.x * 0.5;
			_sizePositionOffsetValue.y = value.y * 0.5;

			_sizePositionOffset = _sizePositionOffsetValue.x != 0 || _sizePositionOffsetValue.y != 0;
			
			_transformDirty = true;
		}

		override protected function updateProperties():void {
			// ничего полезного эта ф-я не делает
		}

		override public function updateTransform(updateProps:Boolean = false):void
		{
			if(!_displayObject)
				return;
			
			if(updateProps)
				updateProperties();
			
			// If size is active, it always takes precedence over scale.
			var tmpScaleX:Number = _scale.x;
			var tmpScaleY:Number = _scale.y;
			/*
			// _size имеет тут совсем другой смысл
			if(_size)
			{
				var localDimensions:Rectangle = _displayObject.getBounds(_displayObject);
				tmpScaleX = _scale.x * (_size.x / localDimensions.width);
				tmpScaleY = _scale.y * (_size.y / localDimensions.height);
			}
			*/
			
			_transformMatrix.identity();
			_transformMatrix.scale(tmpScaleX, tmpScaleY);
			_transformMatrix.translate(-_registrationPoint.x * tmpScaleX, -_registrationPoint.y * tmpScaleY);
			//_transformMatrix.rotate(_rotation * Math.PI * 0.0055555555555555555555 + _rotationOffset);
			tempIsoScreenPoint.x = _position.x + _sizePositionOffsetValue.x + _positionOffset.x;
			tempIsoScreenPoint.y = _position.y + _sizePositionOffsetValue.y + _positionOffset.y;
			isoToScreen(tempIsoScreenPoint);

			positionOffsetScreen.x = _positionOffset.x;
			positionOffsetScreen.y = _positionOffset.y;
			isoToScreen(positionOffsetScreen);

			// учитываем влияние _positionOffset на координату и вычитаем это влияние при просчете pointToDirection
			// (потому что _positionOffset не дорлжна влиять на direction персонажа, а просто на смещение)
			var _positionOffsetScreen:Point = isoToScreen(_positionOffset.clone());

			var lastDirection:int = __direction;
			if(_displayObject.x != 0 && _displayObject.y != 0)// если происходит НЕ инициализация позиции персонажа
				__direction = pointToDirection(
					  tempIsoScreenPoint.x - positionOffsetScreen.x - _displayObject.x + lastAppliedPositionOffsetScreen.x
					, tempIsoScreenPoint.y - positionOffsetScreen.y - _displayObject.y + lastAppliedPositionOffsetScreen.y);

			lastAppliedPositionOffsetScreen.x = positionOffsetScreen.x;
			lastAppliedPositionOffsetScreen.y = positionOffsetScreen.y;
			
			_transformMatrix.translate(tempIsoScreenPoint.x, tempIsoScreenPoint.y);
			_displayObject.transform.matrix = _transformMatrix;
			_displayObject.alpha = _alpha;
			_displayObject.blendMode = _blendMode;
			_displayObject.visible = (alpha > 0);
			
			_transformDirty = false;
		}
		
		
		/**
		 * Инициализация вновь добавленного клипа
		 */
		protected function onClipAdded(mc:MovieClip, branch:int = 0):void
		{
			mc.stop();
			for(var i:int = 0;i<mc.numChildren;i++)
			{
				var child:MovieClip = mc.getChildAt(i) as MovieClip;
				if(child)
					onClipAdded(child, branch + 1);
			}
		}

		/**
		 * Клип добавлен и обработан (например, рекурсивно остановлено воспроизведение)
		 */
		protected function onClipInited(mc:MovieClip):void
		{

		}
		
		
		
		/**
		 * Из координат объекта с вида сверху (в тайловых координатах) возвращает его координаты на экране
		 */		
		public static function isoToScreen(point:Point):Point{
			var sourceX:Number = point.x;
			//point.x = (point.x - point.y) * ISO_ANGLE_COS * TILE_SIZE;
			//point.y = (sourceX + point.y) * ISO_ANGLE_SIN * TILE_SIZE;
			point.y *= TILE_SIZE_Y;
			point.x *= TILE_SIZE_X;
			return point;
		}
		
		/**
		 * Из экранных координат объекта в координаты вида сверху (в тайловых координатах)
		 */		
		public static function screenToIso(point:Point):Point{
			var sourceX:Number = point.x; 
			//point.x = (point.y * DIV_ISO_ANGLE_SIN + point.x * DIV_ISO_ANGLE_COS) * 0.5 / TILE_SIZE;
			//point.y = (point.y * DIV_ISO_ANGLE_SIN - sourceX * DIV_ISO_ANGLE_COS) * 0.5 / TILE_SIZE;
			point.y /= TILE_SIZE_Y;
			point.x /= TILE_SIZE_X;
			return point;
		}
	}
}