package com.somewater.storage {
	import flash.net.SharedObject;

	public class LocalDb implements ILocalDb{

		private static var _instance:LocalDb;

		private var so:SharedObject;

		public function LocalDb() {
			if(_instance)
				throw new Error('Singletone');
			_instance = this;

			so = SharedObject.getLocal('db');
		}

		public static function get instance():ILocalDb
		{
			if(_instance == null)
				new LocalDb();
			return _instance;
		}

		public function get (key:String):Object {
			recreateSharedObject();
			return so.data[key];
		}

		public function set (key:String, data:Object):void {
			recreateSharedObject();
			so.data[key] = data;
			so.flush();
		}

		private function recreateSharedObject():void
		{
			if(so == null)
				so = SharedObject.getLocal('db');
		}
	}
}
