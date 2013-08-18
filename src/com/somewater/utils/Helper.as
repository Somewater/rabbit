package com.somewater.utils {
	public class Helper {
		public static function dateIsNull(date:Date):Boolean {
			return !date || date.time == 0 || isNaN(date.time);
		}

		/**
		 * "http://google.com/hello/world" => "http://google.com"
		 */
		public static function basePath(url:String):String {
			if(url && url.substr(0, 4) == 'http'){
				var idx:int = url.indexOf('/', 8);
				if(idx != -1){
					return url.substr(0, idx);
				}
			}
			return url;
		}
	}
}
