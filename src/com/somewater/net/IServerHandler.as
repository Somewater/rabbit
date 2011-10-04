package com.somewater.net {
	public interface IServerHandler {
		function init(uid:String, key:String):void

		function set base_path(value:String):void

		function call(method:String, data:Object = null, onComplete:Function = null, onError:Function = null, base_path:String = null, params:Object = null):void
	}
}
