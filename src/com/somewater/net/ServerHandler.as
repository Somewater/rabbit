package com.somewater.net
{
	import com.somewater.rabbit.net.*;
	import com.adobe.serialization.json.JSON;
	import com.somewater.net.IServerHandler;

	import flash.events.Event;
	import flash.events.IEventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.events.SecurityErrorEvent;

	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.net.URLRequestMethod;

	import flash.net.URLVariables;

	public class ServerHandler implements IServerHandler
	{
		protected var _base_path:String = 'http://rabbit.asflash.ru/';


		public  static var instance:ServerHandler;
		protected var uid:String;
		protected var key:String;
		
		public function ServerHandler()
		{
			if(instance)
				throw new Error("Singletone");
			else
				instance = this;
		}
		
		public function init(uid:String, key:String):void
		{
			this.uid = uid;
			this.key = key;
		}

		public function set base_path(value:String):void
		{
			this._base_path = value;
		}
		
		public function call(method:String, data:Object = null, onComplete:Function = null, onError:Function = null, base_path:String = null, params:Object = null):void
		{
			var variables:URLVariables = new URLVariables();
			if(data == null)
				data = {};
			variables['json'] = JSON.encode(data);
			variables['uid'] = uid;
			variables['key'] = key;

			var loader:URLLoader = new URLLoader();
			loader.addEventListener(Event.COMPLETE, onCompleteHandler);
			loader.addEventListener(IOErrorEvent.IO_ERROR, onErrorHandler);
			loader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, onErrorHandler);

			var request = new URLRequest();
			request.method = URLRequestMethod.POST;
			request.data = variables;
			request.url = (base_path ? base_path : _base_path) + method;
			loader.load(request);

			function onCompleteHandler(e:Event):void
			{
				clearLoader(e.currentTarget);
				var response:String = URLLoader(e.currentTarget).data;
				var responseObject:Object;
				if(response && response.length)
				{
					try
					{
						if(response.substr(0,2) == 'E_')
							responseObject = {error: response};
						else
							responseObject = JSON.decode(response);
					}catch(e:Error){
						if(onError != null)
							onError({error: "E_PARSING"});
					}
					if(responseObject)
					{
					 	if(responseObject.hasOwnProperty("error")
								 && responseObject.error is String
								 && String(responseObject.error).substr(0,2) == "E_")
						{
							if(onError != null)
								onError(responseObject);
						}
						else
						{
							if(onComplete != null)
									onComplete(responseObject);
						}
					}
					else
					{
						if(onError != null)
							onError({error: "E_PARSING"});
					}
				}else{
					if(onError != null)
						onError({error: "E_EMPTY"});
				}
			}

			function onErrorHandler(e:Event):void
			{
				clearLoader(e.currentTarget);
				if(onError != null)
					onError({error: "E_IO"});
			}

			function clearLoader(l:*):void
			{
				l.removeEventListener(Event.COMPLETE, onCompleteHandler);
				l.removeEventListener(IOErrorEvent.IO_ERROR, onErrorHandler);
				l.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, onErrorHandler);
			}
		}
	}
}