package com.somewater.rabbit.components
{
	import com.greensock.TweenLite;
	import com.greensock.TweenMax;
	import com.pblabs.engine.PBE;
	import com.pblabs.engine.core.IQueuedObject;
	import com.pblabs.engine.debug.Logger;
	import com.pblabs.engine.entity.PropertyReference;
	import com.somewater.rabbit.States;
	import com.somewater.rabbit.iso.IsoMover;
	import com.somewater.rabbit.iso.IsoRenderer;
	import com.somewater.rabbit.iso.IsoSpatial;
	import com.somewater.rabbit.iso.scene.IsoSpatialManager;
	import com.somewater.rabbit.logic.SenseEvent;
	import com.somewater.rabbit.logic.SentientComponent;
	import com.somewater.rabbit.util.RandomizeUtil;
	
	import flash.geom.Point;

	/**
	 * Компонент скрывает персонаж с карты на какое-то время 
	 * (исключая последнего из пересчета карты проходимости и т.д.)
	 * 
	 * Компонент осуществляет 2 вида поведения: 
	 * 	- переместить персонаж в край карты
	 * 	- если персонаж на краю карты, скрыть персонаж
	 */
	public class ConcealComponent extends SentientComponent
	{
		/**
		 * тип чувства, заставляющее двигаться к границе карты
		 */
		private const SENSE_TO_BOUND:String = "senseToBound";
		
		/**
		 * тип чувства, заставляющее скрыться
		 */
		private const SENSE_CONCEAL:String = "senseConceal";
		
		
		private const SENCE_KILL_NOW:String = "senseKillNow";
		
		/**
		 * На каком максимально расстоянии от края карты объект считается достигшим границы
		 */
		private var BORDER_PADDING:Number = 0.1;
		
		/**
		 * Ссылка на @Spatial
		 */
		private var spatialRef:IsoSpatial;
		
		
		/**
		 * Ссылка на @Render
		 */
		private var renderRef:IsoRenderer;
		
		
		/**
		 * Компонент не совершил "умертвление"
		 */
		private var isAlive:Boolean = true;

		/**
		 * Флаг указывает, что позиция на краю карты, сгенерированная в прошлый раз алгоритмом
		 * относительно координат персонажа, недостижима. Т.е. надо попытаться сгенеировать
		 * крайнюю позицию не отталкиваясь от положения персонажа
		 */
		private var unreachableBoundPosition:Boolean = false;
		
		
		/**
		 * Прежде, чем "убить" существо, надо сохранить все первоначальные значения его проходимости
		 */
		private var savedOccupyMask:uint;
		private var savedOccupyMaskRule:uint;
		
		/**
		 * Флаг заставляет компонент скрыть объект (и переместить к краю карты)
		 * при первой возможности (запуске) компонента
		 */
		private var _concealOnStart:Boolean;
		
		
		/**
		 * Минимальное время на "спрятаться" (мс)
		 */
		public var concealMinTime:int = 3000;
		
		
		/**
		 * Максимальное время на "спрятаться" (мс)
		 */
		public var concealMaxTime:int = 10000;
		
		/**
		 * Время "рождения", мс с момента старта флешки
		 */
		private var bornTime:uint = 0;

		/**
		 * Стейт рендера, который был у объекта в последний стейт "при жизни"
		 * (для исправления визуального бага с исчезающей сидячей, а не летящей, вороной)
		 */
		private var lastAliveRenderState:String;
		
		/**
		 * Время жизни (мс), в продолжении которого компонент не стремится спрятаться
		 */
		public var lifeTime:int = 10000;
		
		
		public function set concealOnStart(value:Boolean):void
		{
			registerForTicks = value;
			_concealOnStart = value;
		}
		
		
		override public function onTick(deltaTime:Number):void
		{
			if(_concealOnStart)
			{
				analyze();
				
				_concealOnStart = false;
				registerForTicks = false;
			}
		}
		
		
		
		public function ConcealComponent()
		{
		}
		
		
		override public function analyze():void
		{
			if(_concealOnStart)
			{
				var sense:SenseEvent = getSense(null, SENCE_KILL_NOW);
				sense.priority = 1000;// я оочень хочу убить
				_concealOnStart = false;
				
				_port(sense);
			}
			else
			{
				// компонент "жадный", если персонаж давно не прятался
				if(PBE.processManager.virtualTime - bornTime > lifeTime)
					_port(getSense(null, checkBoundPosition()?SENSE_CONCEAL:SENSE_TO_BOUND));
			}
		}
		
		// вывести сущность из мира живых
		override public function startAction(sense:SenseEvent):void
		{
			if(sense.senseType == SENSE_TO_BOUND)
			{
				if(spatialRef == null)
					createSpatialRef();
				
				if(spatialRef == null)
				{
					_port(null);
					return;
				}
				
				// послать к краю
				IsoMover(owner.lookupComponentByName("Mover")).
					setDestination(getBoundPosition(true), onBoundDestinated, onBoundDestinatedError);
			}
			else
			{
				// скрыть
				if(isAlive)
					dead();
			}
		}
		
		
		
		override protected function onReset():void
		{
//			if(concealOnStart && isAlive)// HOOK
//			{
//				createRenderRef();
//				createSpatialRef();
//				
//				if(renderRef && spatialRef)
//				{
//					dead();
//					concealOnStart = false;
//				}
//			}
		}
		
		
		
		
		private function onBoundDestinated():void
		{
			_port(getSense(null, SENSE_CONCEAL));
		}
		
		private function onBoundDestinatedError():void
		{
			Logger.warn(this, "onBoundDestinatedError", "Pathfinding error in bounds movement");
			unreachableBoundPosition = true;
			_port(null);// по какой-то невероятной причине до края невозможно дойти
		}
		
		
		// вернуть сущность в мир живых
		override public function breakAction():void
		{
			if(isAlive == false)
				alive();
		}
		
		/**
		 * @return объект подошел непосредственно к границе карты
		 */
		private function checkBoundPosition():Boolean
		{
			if(spatialRef == null)
				createSpatialRef();
			
			if(spatialRef)
			{
				var p:Point = spatialRef.position;
				if(Math.abs(spatialRef.position.x - IsoSpatialManager.instance.width) < BORDER_PADDING)
					return true;// слева или справа
				else if(IsoSpatialManager.instance.height - spatialRef.position.y < BORDER_PADDING)
					return true;// снизу (положение сверху не в счет, там еще горизонт
				else 
					return false;
			}
			else
				return false;
		}
		
		
		/**
		 * @return ближайшую точку на границе игрового поля, 
		 * куда следует поместить персонаж
		 */
		private function getBoundPosition(sharpen:Boolean = false):Point
		{
			var pos:Point = unreachableBoundPosition ? null : spatialRef._position;
			unreachableBoundPosition = false;
			var sceneWidth:int = IsoSpatialManager.instance.width;
			var sceneHeight:int = IsoSpatialManager.instance.height;
			
			if(pos == null || pos.x == int.MIN_VALUE || pos.y == int.MIN_VALUE)
			{
				// если позиция объекта еще не была определена, генерируем рандом
				pos = RandomizeUtil.RandomTilePoint();
			}
			
			var toLeft:Number = pos.x - BORDER_PADDING;
			var toRight:Number = sceneWidth - pos.x - BORDER_PADDING;
			var toBottom:Number = sceneHeight - pos.y - BORDER_PADDING;

			var result:Point;
			if(toLeft < toRight && toLeft < toBottom)
				result = new Point(BORDER_PADDING, pos.y);
			else if(toRight < toLeft && toRight < toBottom)
				result = new Point(sceneWidth - BORDER_PADDING, pos.y);
			else
				result = new Point(pos.x, sceneHeight - BORDER_PADDING);
			
			if(sharpen)
			{
				result.x = int(result.x);
				result.y = int(result.y);
			}
			
			return result;
		}
		
		
		override protected function onRemove():void
		{
			super.onRemove();
			
			spatialRef = null;
		}
		
		
		/**
		 * "Оживить"
		 */
		private function alive():void
		{
			if(spatialRef == null)
				createSpatialRef();
			
			if(spatialRef)
			{
				spatialRef.occupyMask = savedOccupyMask;
				spatialRef.occupyMaskRule = savedOccupyMaskRule;
				var p:Point = spatialRef.tile;
				var s:Point = spatialRef._size;
				IsoSpatialManager.instance.refreshRegistration(spatialRef, p.x, p.y, s.x, s.y, 0.0, 0.0, 0.0, 0.0, 1); 
			}
			
			createRenderRef();
			if(renderRef)
			{
				show();
				renderRef.state = lastAliveRenderState;// мы насильно ранее перевели объект в стейт "walk", теперь возвращаем как было
			}
			
			isAlive = true;
		}
		
		
		/**
		 * "Убить"
		 */
		private function dead():void
		{
			if(spatialRef == null)
				createSpatialRef();
			
			if(spatialRef)
			{
				spatialRef.position = getBoundPosition();
				
				savedOccupyMask = spatialRef.occupyMask;
				savedOccupyMaskRule = spatialRef.occupyMaskRule;
				var p:Point = spatialRef.tile;
				var s:Point = spatialRef._size;
				IsoSpatialManager.instance.refreshRegistration(spatialRef, p.x, p.y, s.x, s.y, 0.0, 0.0, 0.0, 0.0, 1); 
			}
			
			// а также остановить любое движение
			owner.setProperty(new PropertyReference("@Mover.destination"), null);

			createRenderRef();
			if(renderRef)
			{
				hide();
				lastAliveRenderState = renderRef.state;
				renderRef.state = States.WALK;// Чтобы исчезала летящая ворона, а не сидящая на месте
			}

			isAlive = false;
			
			// и поставить таймер на последующее "оживление"
			var delay:Number = concealMinTime + (concealMaxTime - concealMinTime) * RandomizeUtil.rnd;
			PBE.processManager.schedule(delay, this, onBorn);
		}
		
		
		/**
		 * Создать (если необходимо) ссылки на другие компоненты
		 * Необходимо вызывать данную ф-ю перед использованием других компонент
		 */
		private function createSpatialRef():void
		{
			if(spatialRef == null)
				spatialRef = owner.lookupComponentByName("Spatial") as IsoSpatial;
		}
		private function createRenderRef():void
		{
			if(renderRef == null)
				renderRef = owner.lookupComponentByName("Render") as IsoRenderer;
		}
		
		
		
		public function get nextThinkCallback():Function
		{
			return alive;
		}
		
		/**
		 * Начать думать, после долгого бездействия 
		 * в спрятанном состоянии
		 */
		protected function onBorn():void
		{
			if(!owner) return;// похоже, что компонент был убит
			
			alive();
			
			bornTime = PBE.processManager.virtualTime;
			
			if(_driving)
				_port(null);
		}
		
		private function show():void
		{
			renderRef.visible = true;
			renderRef.alpha = 0;
			TweenMax.to(renderRef, 0.4,{"alpha":1})
		}
		
		private function hide():void
		{
			renderRef.visible = false;
		}
	}
}