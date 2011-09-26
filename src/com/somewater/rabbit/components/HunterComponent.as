package com.somewater.rabbit.components
{
	import com.pblabs.engine.entity.PropertyReference;
	import com.somewater.rabbit.iso.IsoMover;
	import com.somewater.rabbit.iso.IsoSpatial;
	import com.somewater.rabbit.logic.SenseEvent;
	
	import flash.geom.Point;

	/**
	 * Производит погоню, следование за персонажами (victim) заданного(ых) типа(ов)
	 * При достижении victim-ов сам никаких действий не производит
	 */
	public class HunterComponent extends FinderComponentBase
	{
		
		private var destination:PropertyReference;
		
		/**
		 * Последняя точка, до которой так и не удалось добраться
		 * (чтобы компонент "не кидался" вновь и вновь на недоступную жертву)
		 */
		private var lastUnhappyPoint:Point;
		
		/**
		 * Сколько раз персонаж попытайтеся добраться до 
		 * lastUnhappyPoint перед тем, как оставит это дело
		 */
		public var effortMax:int = 2;
		
		internal var effortCurrent:int;
		
		/**
		 * Точка, за которой "охотятся" в данный момент
		 */
		private var currentHuntedPoint:Point;
		
		/**
		 * Флаг, означающий, что компонент слушает и обрабатывет колбэки из @Mover
		 * (false позволяет не отвязывая колбеков от @Mover, запретить его слушать - 
		 * при отвязывании можно затереть чужие колбэки)
		 */
		private var listenForMoving:Boolean;
		
		private var age:int;
		
		public function HunterComponent()
		{
			super();
			
			destination = new PropertyReference("@Mover.destination");
			
			registerForTicks = true;
		}
		
		
		override public function onTick(deltaTime:Number):void
		{
			if(_driving == false)
			{
				// периодически "проверяем окрестности"
				if(age++ % 5 == 0)
				{
					analyze();
				}
			}
		}
		
		
		override public function analyze():void
		{
			var victims:Array = searchVictims();
			
			if(victims.length)
			{
				if(lastUnhappyPoint && effortCurrent >= effortMax)
				{
					// проверка на "удачность" позиций
					var i:int = 0;
					while(i < victims.length)
					{
						if(IsoSpatial(victims[i]).tile.equals(lastUnhappyPoint))
							victims.splice(i, 1);
						else
							i++;
					}
					
					if(victims.length)
					{
						_port(getSense({"victims":victims}));
					}
				}
				else
				{
					_port(getSense({"victims":victims}));
				}
			}
		}
		
		
		override public function startAction(sense:SenseEvent):void
		{
			if(sense.data.hasOwnProperty("victims") 
				&& sense.data.victims.length 
				&& IsoSpatial(sense.data.victims[0]).isRegistered)
			{
				currentHuntedPoint = IsoSpatial(sense.data.victims[0]).tile;
				listenForMoving = true;
				IsoMover(owner.lookupComponentByName("Mover")).setDestination(
									currentHuntedPoint,	onHuntedSuccess, onHuntedError);
			}
			else
			{
				_port(null);
			}
		}
		
		
		override public function breakAction():void
		{
			listenForMoving = false;
			// остановить движение к жертве
			IsoMover(owner.lookupComponentByName("Mover")).destination = null;
		}
		
		// мы достигли точки, о котрой мечтали
		private function onHuntedSuccess():void
		{
			if(listenForMoving)
			{
				currentHuntedPoint = null;
				lastUnhappyPoint = null;				
				listenForMoving = false;
				_port(null);
			}
		}
		
		// мы не достигли точки, о которой мечтали
		private function onHuntedError():void
		{
			if(listenForMoving)
			{
				if(lastUnhappyPoint && lastUnhappyPoint.equals(currentHuntedPoint))
				{
					effortCurrent++;
				}
				else
				{
					lastUnhappyPoint = currentHuntedPoint.clone();
					effortCurrent = 0;
				}
				
				currentHuntedPoint = null;				
				listenForMoving = false;
				_port(null);
			}
		}
	}
}