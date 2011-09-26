package com.somewater.rabbit.storage
{
	import com.somewater.social.SocialUser;
	import com.somewater.storage.InfoDef;

	public class GameUser extends InfoDef
	{
		public var socialUser:SocialUser;
		
		protected var _score:int;
		protected var _levelId:int = -1;
		
		public function GameUser(data:Object = null)
		{
			super(data)
		}
		
		override public function set data(value:Object):void
		{
			if(value is SocialUser)
				this.socialUser = value as SocialUser;
			else
				super.data = value;
		}
		
		public function set levelId(value:int):void
		{
			_levelId = value;
		}
		public function get levelId():int {return _levelId;}
		public function get level():LevelDef{return Config.application.getLevelById(_levelId);}
		
		public function set score(value:int):void
		{
			_score = value;
		}
		public function get score():int {return _score;}
	}
}