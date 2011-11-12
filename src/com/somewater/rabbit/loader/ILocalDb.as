package com.somewater.rabbit.loader {
	public interface ILocalDb {
		function get(key:String):Object

		function set(key:String, data:Object):void
	}
}
