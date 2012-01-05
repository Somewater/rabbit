package com.somewater.rabbit.events
{
	import flash.events.Event;
	
	public class ExceptionEvent extends Event
	{
		public static const TICK_EXCEPTION:String = 'someException';
		
		public var error:Error;
		
		public function ExceptionEvent(type:String, error:Error)
		{
			this.error = error;
			super(type, false, false);
		}
	}
}