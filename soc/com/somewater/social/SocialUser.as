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

		public var photos:Array = [];
		public function get photoSmall():String{return photos[0];}
		public function get photoMedium():String{return photos[1]?photos[1]:photos[0];}
		public function get photoBig():String{return photos[photos.length];}
		
		public var isAppFriend:Boolean = false; // appfriend sets from outside
		public var isFriend:Boolean = false;
		public var itsMe:Boolean = false;// данный объект SocialUser описывает самого пользователя игры

		[Deprecated(message='use birthday')]
		public function get bdate():Number{return birthday.time}

		public var birthday:Date = new Date(1990);

		public var city : String;
		public var cityCode:int;
		public var country : String;
		public var countryCode:int;
		
		public var locale:String = "en";

		public var homepage:String;// адрес странички юзера
		
		internal var _sex : uint;
		public function get sex():String{
			return _sex?_sex == SEX_MALE?"male":"female":null;
		}
		public function set sex(value:String):void
		{
			if(value)
			{
				var char:String = value.charAt().toLowerCase();
				if(char == "m")
					_sex = SEX_MALE;
				else if(char == "f")
					_sex = SEX_FEMALE;
				else 
					_sex = SEX_NONE;
			}
			else
				_sex = SEX_NONE;
		}
		public function get male():Boolean { return _sex == SEX_MALE;	}
		public function set male(value:Boolean):void{_sex = value ? SEX_MALE : SEX_FEMALE;}
		public function get female():Boolean { return _sex == SEX_FEMALE;	}
		public function set female(value:Boolean):void{_sex = value ? SEX_FEMALE : SEX_MALE;}
		
		
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
