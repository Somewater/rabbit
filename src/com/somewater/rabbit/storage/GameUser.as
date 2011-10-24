package com.somewater.rabbit.storage
{
	import com.somewater.social.SocialUser;
	import com.somewater.storage.InfoDef;

	public class GameUser extends InfoDef
	{
		public var socialUser:SocialUser;
		
		protected var _score:int;
		protected var _levelInstances:Array = [];
		
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
		
		public function addLevelInstance(levelInst:LevelInstanceDef):void
		{
			if(levelInst.success)
				_levelInstances.push(levelInst);
		}
		public function get levelInstances():Array {return _levelInstances.slice();}

		public function getLevelInsanceByNumber(levelNumber:int):LevelInstanceDef
		{
			for each(var li:LevelInstanceDef in _levelInstances)
				if(li.levelDef.number == levelNumber)
					return li;
			return null;
		}

		public function set score(value:int):void
		{
			_score = value;
		}
		public function get score():int {return _score;}

		/**
		 * Максимальный numner, который прошел юзер (фактически Левел юзера)
		 */
		public function get levelNumber():int
		{
			var max:int =1;
			for each(var inst:LevelInstanceDef in levelInstances)
				if(inst.levelDef.number > max)
					max = inst.levelDef.number;
			return max;
		}
	}
}