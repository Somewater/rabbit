package com.somewater.social
{
	public class SocialUser{
		
		internal static const SEX_NONE : uint = 0;
		internal static const SEX_MALE : uint = 1;
		internal static const SEX_FEMALE : uint = 2;
		
		public var firstName:String;
		public var lastName:String;
		public var nickName:String;
		
		public var id:String;
		public var serverId:String;
		
		public var photos:Array = [];
		public function get photoSmall():String{return photos[0];}
		public function get photoMedium():String{return photos[1]?photos[1]:photos[0];}
		public function get photoBig():String{return photos[photos.length];}
		
		public var isAppFriend:Boolean = false; // appfriend sets from outside
		public var isFriend:Boolean = false;
		public var itsMe:Boolean = false;// данный объект SocialUser описывает самого пользователя игры
		
		public var bdate:Number = 0;// дата рождение timestamp (секунды)		
		public var balance : Number = 0;
		
		public var city : String;
		public var cityCode:int;
		public var country : String;
		public var countryCode:int;
		
		public var locale:String = "en";
		
		internal var _sex : uint;
		public function get sex():String{
			return _sex?_sex == 1?"male":"female":null;
		}
		public function set sex(value:String):void
		{
			if(value)
			{
				var char:String = value.charAt().toLowerCase();
				if(char == "m")
					_sex = 1;
				else if(char == "f")
					_sex = 2;
				else 
					_sex = 0;
			}
			else
				_sex = 0;
		}
		public function get male():Boolean { return _sex == 1;	}
		public function set male(value:Boolean):void{_sex = 1;}
		public function get female():Boolean { return _sex == 2;	}
		public function set female(value:Boolean):void{_sex = 2;}
		
		
		public function SocialUser() {
			
		}
		
		
		public function get name() : String {
			return (firstName?firstName:"") + (firstName && lastName?" ":"") + (lastName?lastName:"");
		}
		
		
		public function toString():String{
			return "[SocialUser(" + name + ")]";
		}
		
	}
}
