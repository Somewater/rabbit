package com.somewater.net {
	public interface IServerHandler {
		function init(uid:String, key:String, net:int):void

		function set base_path(value:String):void

		function get base_path():String

		function call(method:String, data:Object = null, onComplete:Function = null, onError:Function = null, base_path:String = null, params:Object = null):void

		function resetUid(uid:String):void

		function addGlobalHandler(success:Boolean, callback:Function):void

		function toJson(object:Object):String

		function fromJson(json:String):Object

		function stat(name:String):void
	}
}
