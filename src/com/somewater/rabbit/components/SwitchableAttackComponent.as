package com.somewater.rabbit.components
{
	import com.somewater.rabbit.logic.SenseEvent;

	/**
	 * Атакующий компонент, который можно включать/выключать
	 * во включенном состоянии ничем не отличается от AttackComponent
	 * в выключенном состоянии не делает ничего
	 * 
	 * Кроме того, компонент может (и должен) работать вне структуры логических компонентов
	 */
	public class SwitchableAttackComponent extends AttackComponent
	{
		protected var _enabled:Boolean = true;
		
		public function SwitchableAttackComponent()
		{
			super();
			_port = portEmulation;
			enabled = false;// по умолчанию выключен
		}
		
		public function set enabled(value:Boolean):void
		{
			registerForTicks = _enabled = value;
		}
		
		public function get enabled():Boolean
		{
			return _enabled;
		}
		
		/**
		 * Этот компонент, унаследованный от логического, управляет сам собой :)
		 */
		private function portEmulation(sense:SenseEvent):void
		{
			CONFIG::debug
			{
				if(!_enabled)
					throw new Error("Wrong logic. Disabled component can`t use port");
			}
			if(sense)
			{
				_driving = true;
				startAction(sense);
			}
			else if(_driving)
			{
				_driving = false;
				breakAction();
			}
		}
		
		override public function set port(portCallback:Function):void
		{
			throw new Error("I`m free non-logic component!");
		}
		
		override public function onTick(deltaTime:Number):void
		{
			CONFIG::debug
			{
				if(!_enabled)
					throw new Error("Wrong logic. Disabled component can`t tick");
			}
			
			if(_driving)
				action();
			else
				analyze();
		}
		
		public function get driving():Boolean
		{
			return _driving;
		}
	}
}