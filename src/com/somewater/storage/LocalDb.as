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
			return so ? so.data[key] : null;
		}

		public function set (key:String, data:Object):void {
			recreateSharedObject();
			if(so)
			{
				so.data[key] = data;
				so.flush();
			}
		}

		private function recreateSharedObject():void
		{
			if(so == null)
			{
				try
				{
					so = SharedObject.getLocal('db', '/');
				}catch(err:Error)
				{
					trace("[LOCAL DB] Shared object creation error");
				}
			}
		}
	}
}
