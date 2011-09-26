package com.progrestar.common.polygonal
{
	import flash.events.Event;
	
	public class PolyPathFinderEvent extends Event
	{
		public static const PATH_FOUND:String = "pathFound";
		public static const PATH_NOT_FOUND:String = "pathNotFound";
		
		public var path:Array;
		public var request : PathRequest;
		
		public function PolyPathFinderEvent(type:String, path:Array, request:PathRequest, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			this.path = path;
			this.request = request;
			
			super(type, bubbles, cancelable);
		}
		
		override public function clone():Event
		{
			return new PolyPathFinderEvent(type, path, request, bubbles, cancelable);
		}
	}
}