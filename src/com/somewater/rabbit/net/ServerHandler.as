package com.somewater.rabbit.net
{
	public class ServerHandler extends ServerHandlerBase
	{
		public  static var instance:ServerHandler;
		
		public function ServerHandler(uid:String, key:String)
		{
			super(uid, key);
			
			if(instance)
				throw new Error("Singletone");
			else
				instance = this;
		}
		
		public static function init(uid:String, key:String):ServerHandler
		{
			return new ServerHandler(uid, key);
		}
		
		public function initRequest(onComplete:Function, onError:Function):void
		{
			// TODO
			onComplete({});
		}
	}
}