package com.somewater.storage {
	public interface ILocalDb {
		function get(key:String):Object

		function set(key:String, data:Object):void
	}
}
