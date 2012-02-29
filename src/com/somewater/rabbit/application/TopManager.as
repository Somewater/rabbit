package com.somewater.rabbit.application {
	import com.somewater.rabbit.storage.TopUser;

	public class TopManager {

		public static const TYPE_STARS:String = 'stars';

		private static var _instance:TopManager;

		private var topsByType:Array = [];
		private var _dataLoaded:Boolean = false;

		public static function get instance():TopManager
		{
			if(_instance == null)
				_instance = new TopManager();
			return _instance;
		}

		public function TopManager() {
		}

		public function get dataLoaded():Boolean
		{
			return _dataLoaded;
		}

		public function read(data:Object):void
		{
			_dataLoaded = true;
			topsByType = [];
			for(var topType:String in data)
			{
				var topStr:String = data[topType];
				if(topStr.charAt(topStr.length - 1) == ';')
					topStr = topStr.substr(0, topStr.length - 1);
				var topData:Array = topStr.split(';');
				var top:Array = [];
				for (var i:int = 0; i < topData.length; i+=2) {
					var user:TopUser = new TopUser();
					user.uid = topData[i];
					user.value = topData[i + 1];
					top.push(user);
				}
				top.sortOn('value', Array.NUMERIC | Array.DESCENDING);
				if(top.length > 50)top.length = 50
				topsByType[topType] = top;
			}
		}

		/**
		 * array of TopUser
		 * @param topType
		 * @return
		 */
		public function getUsersByTopType(topType:String):Array
		{
			return topsByType[topType] || [];
		}
	}
}
