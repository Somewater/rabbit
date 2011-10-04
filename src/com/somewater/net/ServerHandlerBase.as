package com.somewater.net
{
	
	import com.adobe.serialization.json.JSON;
	
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.SecurityErrorEvent;
	import flash.net.URLLoader;
	import flash.net.URLLoaderDataFormat;
	import flash.net.URLRequest;
	import flash.net.URLRequestMethod;
	import flash.net.URLVariables;
	import flash.utils.Dictionary;
	
	/**
	 * Осуществляет взаимодействие с сервером игры
	 * Запрос к серверу может обрабатываться как единичным callBack, ассоциируемым только с этим запросом,
	 * так и общими обработчиками всех серверных запросов со специфическим полем method
	 */
	public class ServerHandlerBase
	{										
		private const SERVER_PATH:String = "http://79.125.60.20/mail/";// -оригинал mail
		private const ENCRYPTION:Boolean = false;
		
		private var _uid:String;// идентификатор пользователя в соц. сети
		private var _key:String;// защищенный ключ, позволяющий подписывать запросы пользтвателя соц. сети
		
		private var _serverListeners:Dictionary;
		
		
		
		/**
		 * @param uid идентификатор игрока
		 * @param key индивидуальная подпись запросов
		 */
		public function ServerHandlerBase(uid:String, key:String)
		{
			_uid = uid;
			_key = key;
			_serverListeners = new Dictionary();
		}
		
		
		/**
		 * Добавить функцию, выполняемую при определенном ответе от сервера 
		 * @param method наименование серверного ответа, результат которого возвращается функции
		 * @param callBack
		 * @param priority приоритет функции относительно других, слушающих тот же ответ
		 * 
		 */
		public function addServerResponseListener(method:String, callBack:Function, priority:int = 0):void{
			if(_serverListeners[method] == null)
				_serverListeners[method] = [];
				
			var listener:ServerListener = new ServerListener(callBack, priority);
			
			for(var i:int = 0; i<_serverListeners[method].length; i++)
				if(ServerListener(_serverListeners[method][i]).priority <= priority){
					_serverListeners[method].splice(i, 0, listener);
					return;
				}
				
			_serverListeners[method].push(listener);
		}
		
		
		/**
		 * Удалить функцию, выполняемую при определенном ответе от сервера 
		 * @param method наименование серверного ответа
		 * @param callBack
		 * 
		 */
		public function removeServerResponseListener(method:String, callBack:Function):void{
			if(_serverListeners[method]){
				for(var i:int = 0; i<_serverListeners[method].length; i++)
					if(ServerListener(_serverListeners[method][i]).listener == callBack){
						_serverListeners[method].splice(i, 1);
						return;
					}
			}
		}
		
		
		//////////////////////////////////////////////////////////////////////////////////	
		//                                                                        		//
		//                                PRIVATE                                       //
		//                                                                              //
		//////////////////////////////////////////////////////////////////////////////////
		
		
		/**
		 * Обработчик любых ответов сервера
		 */
		private function _serverResponseHandler(method:String, response:Object):void{
			if(_serverListeners[method]){
				for(var i:int = 0; i<_serverListeners[method].length; i++){
					ServerListener(_serverListeners[method][i]).listener(response);
				}
			}
		}

		
		/**
		 * Послать запрос на сервер, с заданными полями 
		 * @param method
		 * @param options перечисленные переменные:значения, отправляемые на сервер
		 * @param onComplete 
		 * @param onError
		 * @param GET метод передачи данных
		 * 
		 */
		private function _sendRequest(method:String, options:Object = null, onComplete:Function = null, onError:Function = null, GET:Boolean = false):void {     		
  
			var urlRequest:URLRequest = new URLRequest(options?(options.url?options.url:(options.relative_url?SERVER_PATH + options.relative_url: SERVER_PATH)):SERVER_PATH);
			urlRequest.method = GET?URLRequestMethod.GET:URLRequestMethod.POST;
			if(GET && ENCRYPTION)
				throw new Error("Encryption algorithm does not support GET method");
			
			var data:URLVariables = new URLVariables();
			
			if(options){
				delete options["url"];
				delete options["relative_url"];
				for(var s:String in options)
					data[s] = options[s];
			}
			data["method"] = method;
			data["uid"] = _uid;
			data["auth_key"] = _key;
				
			var urlLoader:URLLoader = new URLLoader();
			urlLoader.addEventListener(Event.COMPLETE, onLoaderComplete);
			urlLoader.addEventListener(IOErrorEvent.IO_ERROR, onIOError);
			urlLoader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, onSecurityError);
			
			if(ENCRYPTION){
				var dataToString:String = "";
				
				for(var i:String in data ){
					var o:Object;
					if(!(data[i] is Array) && !(data[i] is String))
						o = JSON.encode(data[i]);
					else
						o = data[i];
					dataToString += "&"+i+"="+o;
				}
				
				urlRequest.contentType = "application/octet-stream";
				urlLoader.dataFormat = URLLoaderDataFormat.BINARY;
				urlRequest.data = null; throw new Error("TODO");
			}else{
				urlRequest.data = data;
			}
			
			urlLoader.load(urlRequest);			
			
			function onLoaderComplete(e:Event):void{
				clearLoader(e.target);
				var serverResponse:Object;
				try{
					serverResponse = JSON.decode(e.target.data);
				}catch(e:Error){
					if(onError)
						onError({error:"json error"});
				}
				if(!serverResponse || serverResponse == "" || serverResponse == "null" || serverResponse.errors){
					if(onError)
						onError(!serverResponse || !serverResponse.hasOwnProperty("errors")?"Empty server response":serverResponse.errors);
					trace("Server error: " + (serverResponse?serverResponse.errors:"<empty>"));	
					
				}else{
					var serverMethod:String = serverResponse.method;
					if(onComplete)
						onComplete(serverResponse.response?serverResponse.response: serverResponse);
					
					_serverResponseHandler(serverMethod, serverResponse.response);
				}
			}
			
			function onIOError(e:IOErrorEvent):void{
				clearLoader(e.target);
				if(onError)
					onError({error:e.text});
			}
			
			function onSecurityError(e:SecurityErrorEvent):void{
				clearLoader(e.target);
				if(onError)
					onError({error:e.text});
			}
			
			function clearLoader(loader:URLLoader):void{
				loader.removeEventListener(Event.COMPLETE, onLoaderComplete);
				loader.removeEventListener(IOErrorEvent.IO_ERROR, onIOError);
				loader.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, onSecurityError);
			}
		
		}
	}
}
	

class ServerListener{
	
	public function ServerListener(_listener:Function, _priority:int):void{
		listener = _listener;
		priority = _priority;
	}
	
	public var listener:Function;
	public var priority:int;
}