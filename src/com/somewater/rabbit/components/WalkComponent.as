package com.somewater.rabbit.components
{
	import com.pblabs.engine.PBE;
	import com.pblabs.engine.entity.PropertyReference;
	import com.somewater.rabbit.iso.IsoMover;
	import com.somewater.rabbit.logic.SenseEvent;
	import com.somewater.rabbit.logic.SentientComponent;
	import com.somewater.rabbit.util.RandomizeUtil;
	
	import flash.geom.Point;
	
	/**
	 * Заставляет персонажа совершать хождения туда-сюда, без цели
	 * Также, отвечает за бесцельное стояние
	 */
	public class WalkComponent extends SentientComponent
	{
		/**
		 * Шанс того, что персонаж замрет на некоторое время без движений
		 * (если 0, то персонаж всегда в движении)
		 */
		public var standChance:Number = 0;
		
		/**
		 * Минимальное время стояния без действий
		 * Если standChance == 0, значение переметра не используется
		 */
		public var minStandTime:int = 500;
		
		/**
		 * Максимальное время стояния без действий
		 * Если standChance == 0, значение переметра не используется
		 */
		public var maxStandTime:int = 1500;
		
		/**
		 * Флаг, не позволяющий "стоять" при первом обращении к компоненту. 
		 * Чтобы песонаж при старте игры сдвинулся с места (напр. собака вышла из будки)
		 */
		private var initialized:Boolean = false;
		
		private var destinationRef:PropertyReference;
		
		public function WalkComponent()
		{
			super();
			
			destinationRef = new PropertyReference("@Mover.destination");
		}
		
		
		override public function analyze():void
		{
			if(initialized && RandomizeUtil.rnd < standChance)
			{
				// стоим на месте
				_port(getSense({"value": null}));
			}
			else
			{
				initialized = true;
				var destination:Point = owner.getProperty(destinationRef);
				if(destination == null)
				{
					var value:Point = RandomizeUtil.RandomTilePoint_free();
					_port(getSense({"value": value}));
				}
			}
		}
		
		
		override public function startAction(sense:SenseEvent):void
		{
			if(sense.data.hasOwnProperty("value") && sense.data.value)
			{
				IsoMover(owner.lookupComponentByName("Mover")).setDestination(sense.data.value,
					onWalkSuccess, onWalkError);
			}
			else
			{
				PBE.processManager.schedule(minStandTime + RandomizeUtil.rnd * (maxStandTime - minStandTime), null, onWalkError);
			}
		}
		
		
		private function onWalkSuccess():void
		{
			_port(null);
		}
		
		private function onWalkError():void
		{
			if(_port)
				_port(null);
		}
	}
}