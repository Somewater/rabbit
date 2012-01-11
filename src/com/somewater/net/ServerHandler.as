package com.somewater.net
{
	import com.adobe.crypto.MD5;
	import com.adobe.serialization.json.JSON;
	import com.somewater.net.IServerHandler;
	import com.somewater.rabbit.net.*;
	import com.somewater.rabbit.storage.Config;

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
		protected var net:int;

		private var ping:int = 0;

		protected var _globalHandlersSuccess:Array = [];
		protected var _globalHandlersError:Array = [];
		
		public function ServerHandler()
		{
			if(instance)
				throw new Error("Singletone");
			else
				instance = this;
		}
		
		public function init(uid:String, key:String, net:int):void
		{
			this.uid = uid;
			this.key = key;
			this.net = net;
		}

		public function set base_path(value:String):void
		{
			this._base_path = value;
		}
		
		public function get base_path():String
		{
			return this._base_path;
		}
		
		public function call(method:String, data:Object = null, onComplete:Function = null, onError:Function = null, base_path:String = null, params:Object = null):void
		{
			var variables:URLVariables = createUrlVariables(method, data, params);

			var loader:URLLoader = new URLLoader();
			loader.addEventListener(Event.COMPLETE, onCompleteHandler);
			loader.addEventListener(IOErrorEvent.IO_ERROR, onErrorHandler);
			loader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, onErrorHandler);

			var request:URLRequest = new URLRequest();
			request.method = URLRequestMethod.POST;
			request.data = variables;
			request.url = (base_path ? base_path : _base_path) + method;
			try
			{
				loader.load(request);
			}catch(err:SecurityError)
			{
				if(onError != null)
					onError({error: "E_SECURITY"});
			}

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
						fireCallbacks(false, onError, {error: "E_PARSING"});
						return;
					}
					if(responseObject)
					{
					 	if(responseObject.hasOwnProperty("error")
								 && responseObject.error is String
								 && String(responseObject.error).substr(0,2) == "E_")
						{
							fireCallbacks(false, onError, responseObject);
						}
						else
						{
							fireCallbacks(true, onComplete, responseObject);
						}
					}
					else
					{
						fireCallbacks(false, onError, {error: "E_PARSING"});
					}
				}else{
					fireCallbacks(false, onError, {error: "E_EMPTY"});
				}
			}

			function onErrorHandler(e:Event):void
			{
				clearLoader(e.currentTarget);
				fireCallbacks(false, onError, {error: "E_IO"});
			}

			function clearLoader(l:*):void
			{
				l.removeEventListener(Event.COMPLETE, onCompleteHandler);
				l.removeEventListener(IOErrorEvent.IO_ERROR, onErrorHandler);
				l.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, onErrorHandler);
			}
		}

		protected function createUrlVariables(method:String, data:Object = null, params:Object = null):URLVariables
		{
			var variables:URLVariables = new URLVariables();
			if(data == null)
				data = {};
			variables['json'] = JSON.encode(data);
			variables['uid'] = uid;
			variables['key'] = key;
			variables['net'] = net;
			variables['ping'] = getPing();
			if(params && params['secure'] != null)
				variables['secure'] = createSecureHash(variables['json'], params['secure']);
			return variables;
		}

		private function get secureRoll():int
		{
			return 1;
		}

		private function createSecureHash(jsonString:String, roll:int):String {
			/*var str:String = "";
			for(var i:int = jsonString.length - 1; i >= 0; i--)
			{
				str += jsonString.charAt(i);
			}*/
			return MD5.encrypt(Config.loader.secure(secureRoll * 0.01, uid, net.toString(), jsonString));
		}

		protected function getPing():int
		{
			ping++;
			return ping;
		}

		public function resetUid(uid:String):void
		{
			if(this.uid == uid)
			{
				// nothing
			}
			else if(this.uid == null || this.uid.length == 0 || this.uid == '0' || this.uid == 'null')
				this.uid = uid;
			else
				throw new Error('Uid already specificated');
		}

		public function addGlobalHandler(success:Boolean, callback:Function):void
		{
			if(success && _globalHandlersSuccess.indexOf(callback) == -1)
				_globalHandlersSuccess.push(callback);
			else if(!success && _globalHandlersError.indexOf(callback) == -1)
				_globalHandlersError.push(callback);
		}

		public function toJson(object:Object):String
		{
			return JSON.encode(object);
		}

		public function fromJson(json:String):Object
		{
			return JSON.decode(json);
		}

		private function fireCallbacks(success:Boolean, callback:Function, response:Object):void
		{
			if(callback != null)
				callback(response);
			else
				response['no_callback'] = true;

			var handlers:Array = success ? _globalHandlersSuccess : _globalHandlersError;
			for(var i:int = 0;i<handlers.length;i++)
				handlers[i](response);
		}
	}
}