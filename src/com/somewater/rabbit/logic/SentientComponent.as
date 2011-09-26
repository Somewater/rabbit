package com.somewater.rabbit.logic
{
	import com.pblabs.engine.components.TickedComponent;
	
	/**
	 * Наиболее базовое исполнение интерфейса ISentientComponent
	 * @see com.somewater.rabbit.logic.ISentientComponent
	 */
	public class SentientComponent extends TickedComponent implements ISentientComponent
	{
		/**
		 * Ссылка на LogicComponent.port(event:SenseEvent):void
		 */
		protected var _port:Function;// function(event:SenseEvent):void
		
		/**
		 * Приоритет компонента, который автоматически проставляется всем SenseEvent
		 */
		protected var _priority:int = 0;
		
		/**
		 * Флаг, означающий, что данный компонент является ведущим - т.е. ему передано управление
		 */
		protected var _driving:Boolean = false;
		
		public function SentientComponent()
		{
			super();
			
			// по умолчанию не тикается
			registerForTicks = false;
		}
		
		public function set port(portCallback:Function):void
		{
			_port = portCallback;
		}
		
		/**
		 * Если конкретная реализация компонента "тикается", то
		 * вызывается ф-я analyze, т.е. компонент "чувствует" каждый тик
		 */
		override public function onTick(deltaTime:Number):void
		{
			analyze();
		}
		
		public function startAction(sense:SenseEvent):void
		{
		}
		
		public function action():void
		{
		}
		
		public function breakAction():void
		{
		}
		
		public function analyze():void
		{
			throw new Error("Must be overriden");
		}
		
		public function get priority():int
		{
			return _priority;
		}
		
		public function set priority(value:int):void
		{
			_priority = value;
		}
		
		/**
		 * Рекомендуется через данную ф-ю создавать события
		 * При необходимости, можно вручную выставить им особый приоритет
		 */
		protected function getSense(data:Object = null, senseType:String = null):SenseEvent
		{
			return new SenseEvent(this, senseType?senseType:String(this), _priority, data, false);
		}
		

		override protected function onRemove():void
		{
			super.onRemove();
			// удалить единственную ссылку на старый LogicComponent
			_port = null;
		}
		
		public function set driven(value:Boolean):void
		{
			_driving = value;
		}
		
	}
}