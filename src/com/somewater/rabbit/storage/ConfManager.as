package com.somewater.rabbit.storage {
	import com.somewater.storage.ILocalDb;

	/**
	 * Читает конфигурационный файл (должен быть в формате json) и типизирует его ключи
	 */
	public class ConfManager implements ILocalDb{

		public static const ITEMS_KEY:String = 'ITEMS';

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
			var regexp:RegExp = /(\w+)\=(.+)\n\n/g
			var str:String = Config.loader.getData('Config');
			data = [];
			jsonCache = [];
			var match:Object;
			while((match = regexp.exec(str)) != null)
			{
				data[String(match[1])] = String(match[2]);
			}
		}
	}
}
