package com.somewater.rabbit.logic
{
	import flash.events.Event;
	
	/**
	 * Событие, отправляемое "чувствующим" компонентом ISentientComponent
	 */
	public class SenseEvent extends Event
	{
		public static const SENSE:String = "sense";
		
		/**
		 * Кто создал событие
		 * (и кому надо передать управление, если событие будет принято за наиболее важное)
		 */
		public var creator:ISentientComponent;
		
		/**
		 * Конкрентный тип, надо задать, если SentientComponent отправляет более одного типа событий
		 * (чтобы сам компонент не запутался, какое из них было выбрано)
		 */
		public var senseType:String;
		
		/**
		 * Приоритет, на основании которого LogicController примет решение об использовании события
		 */
		public var priority:int;
		
		/**
		 * Вспомогательные данные
		 * (например, при SentientComponent.analyze() появились данные, которые неплохо было бы 
		 * сохранить, чтобы вновь не пересчитывать)
		 */
		public var data:Object
		
		public function SenseEvent(creator:ISentientComponent, senseType:String = null,priority:int = -1000000 , data:Object = null,autoDispatch:Boolean = true)
		{
			super(SENSE);
			
			this.creator = creator;
			this.priority = priority != -1000000?priority:creator.priority;
			this.senseType = senseType?senseType:String(creator);
			
			if(data == null)
				this.data = {};
			else
				this.data = data;
			
			if(autoDispatch)
				creator.owner.eventDispatcher.dispatchEvent(this);
		}
		
		override public function clone():Event
		{
			var sense:SenseEvent = new SenseEvent(creator, senseType, priority, data, false);
			
			return sense;
		}
	}
}