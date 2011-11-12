package com.somewater.rabbit.net {
	import com.somewater.net.ServerHandler;

	/**
	 * Эмулирует работу сервера для тестов (для standalone игры)
	 */
	public class LocalServerHandler extends ServerHandler{
		public function LocalServerHandler() {
		}


		override public function call(method:String, data:Object = null, onComplete:Function = null, onError:Function = null, base_path:String = null, params:Object = null):void {
			switch(method)
			{
				case 'init':
					emulateInit(data,onComplete,onError); break
				default:
					throw new Error('Unemulated method ' + method);
			}
		}

		private function emulateInit(data:Object = null, onComplete:Function = null, onError:Function = null):void
		{
			onComplete({"user":{"level":1, "score":34}});
		}
	}
}
