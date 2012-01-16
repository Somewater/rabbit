package clickozavr.GetUserData
{
	import flash.events.Event;
	
	public class GetUserDataEvent extends Event
	{
		public static const GET_USER_DATA_SUCCESS:String = "getUserDataSuccess";
		public static const GET_USER_DATA_FAILED:String = "getUserDataFailed";
		
		public var data:XML;
		
		public function GetUserDataEvent(type:String, data:XML = null, bubbles:Boolean = false, cancelable:Boolean = false)
		{
			super(type, bubbles, cancelable);
			this.data = data;
		}
		
		override public function clone():Event
		{
			return new GetUserDataEvent(type, data, bubbles, cancelable);
		}
	}
}