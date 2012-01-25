package com.somewater.rabbit.storage {
	import com.somewater.storage.ILocalDb;

	/**
	 * Читает конфигурационный файл (должен быть в формате json) и типизирует его ключи
	 */
	public class ConfManager implements ILocalDb{

		protected static var _instance:ConfManager;

		private var data:Array;
		private var jsonCache:Array;

		public function ConfManager() {
			_instance = this;
			read_data();
		}

		public static function get instance():ConfManager
		{
			if(_instance == null)
				new ConfManager();
			return _instance;
		}

		public function get (key:String):Object {
			if(jsonCache[key] == null)
				jsonCache[key] = data[key] ? Config.loader.serverHandler.fromJson(data[key]) : null;
			return jsonCache[key];
		}

		public function getArray(key:String):Array
		{
			return (this.get(key) as Array) || [];
		}

		public function getNumber(key:String):Number
		{
			return data[key] as Number;
		}

		public function getString(key:String):String
		{
			if(Config.application)
				return Config.application.translate(data[key])
			else
				return data[key];
		}

		public function set (key:String, data:Object):void {
			throw new Error('Runtime config editing not implemented');
		}

		private function read_data():void {
			var hash:Object = Config.loader.serverHandler.fromJson(Config.loader.getData('Config'))
			data = [];
			jsonCache = [];
			for(var k:String in hash)
				data[k] = hash[k];
		}
	}
}
