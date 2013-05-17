package com.somewater.rabbit.net {
import com.adobe.crypto.MD5;
import com.adobe.serialization.json.JSON;
import com.somewater.net.IServerHandler;
import com.somewater.net.ServerHandler;
import com.somewater.rabbit.storage.Config;
import com.somewater.storage.ILocalDb;
import com.somewater.storage.LocalDb;

/**
 * Эмулирует работу сервера для тестов (для standalone игры)
 */
public class LocalServerHandlerBase implements IServerHandler{

	protected var uid:String;
	protected var key:String;
	protected var net:int;

	protected var globalHandlersSuccess:Array = [];
	protected var globalHandlersError:Array = [];

	protected var config:Object;

	protected var METHOD_TO_HANDLER:Object = {};

	public function LocalServerHandlerBase(config:Object) {
		this.config = config;
	}

	public function init(uid:String, key:String, net:int):void {
		this.uid = uid;
		this.key = key;
		this.net = net;
	}

	public function set base_path(value:String):void {
	}

	public function get base_path():String {
		return "";
	}

	public function call(method:String, data:Object = null, onComplete:Function = null, onError:Function = null, base_path:String = null, params:Object = null):void {
		Config.callLater(callImmediately, [method, data, onComplete, onError, base_path, params]);
	}

	private function callImmediately(method:String, data:Object = null, onComplete:Function = null, onError:Function = null, base_path:String = null, params:Object = null):void {
		var handler:Function = METHOD_TO_HANDLER[method];
		var globalHandlers:Array;
		var response:Object;
		if(handler != null)
		{
			data['callback'] = onComplete;
			response = handler(data);
			if(response){
				if(onComplete != null)
					onComplete(response);
				globalHandlers = globalHandlersSuccess.slice();
			}
		}
		else
		{
			response = {error:'E_IO'}
			if(onError != null)
				onError(response);
			globalHandlers = globalHandlersError.slice();
		}
		for each(var f:Function in globalHandlers)
			f(response);
	}

	public function resetUid(uid:String):void {
		this.uid = uid;
	}

	public function addGlobalHandler(success:Boolean, callback:Function):void {
		var handlers:Array = success ? globalHandlersSuccess : globalHandlersError;
		if(handlers.indexOf(callback) == -1)
			handlers.push(callback);
	}

	public function toJson(object:Object):String {
		return JSON.encode(object);
	}

	public function fromJson(json:String):Object {
		return JSON.decode(json);
	}

	public function encrypt(str:String):String {
		// на любую строку выдает "hello" - таким образом, проверка авторизации всегда работает верно
		return MD5.encrypt(str);
	}
}
}
