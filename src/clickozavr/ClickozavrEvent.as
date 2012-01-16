package clickozavr
{
	import flash.events.Event;
	
	public class ClickozavrEvent extends Event
	{
		public static const GET_USER_DATA:String = "getUserData";
		public static const CONTAINERS_READY:String = "containersReady";
		
		public function ClickozavrEvent(type:String, bubbles:Boolean = false, cancelable:Boolean = false)
		{
			super(type, bubbles, cancelable);
		}
	}
}