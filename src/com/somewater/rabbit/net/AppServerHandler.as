package com.somewater.rabbit.net {
	import com.somewater.net.IServerHandler;
	import com.somewater.rabbit.storage.Config;

	/**
	 * Прокси между IServerHandler и логикой приложения
	 */
	public class AppServerHandler {

		private static var handler:IServerHandler;

		static public function initRequest(onComplete:Function, onError:Function):void
		{
			handler = Config.loader.serverHandler;
			onComplete({});

			handler.call("init", {social:"LOCAL"}, null, onError);
		}
	}
}
