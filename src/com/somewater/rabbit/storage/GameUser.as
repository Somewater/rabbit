package com.somewater.rabbit.storage
{
	import com.somewater.social.SocialUser;
	import com.somewater.storage.InfoDef;

	public class GameUser extends InfoDef
	{
		public var socialUser:SocialUser;
		
		protected var _score:int;
		protected var _levelInstances:Array = [];
		protected var _rewards:Array = [];
		
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
				_levelInstances[levelInst.number] = levelInst;
		}
		public function get levelInstances():Array {
			var arr:Array = [];
			for each(var li:LevelInstanceDef in _levelInstances)
				arr.push(li);
			return arr;
		}

		public function getLevelInsanceByNumber(levelNumber:int):LevelInstanceDef
		{
			return _levelInstances[levelNumber];
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
			var max:int = 0;
			for each(var inst:LevelInstanceDef in _levelInstances)
				if(inst.levelDef.number > max)
					max = inst.levelDef.number;
			return max + 1;
		}

		/**
		 * Array of RewardDef
		 */
		public function get rewards():Array
		{
			var arr:Array = [];
			for each(var r:RewardInstanceDef in _rewards)
				arr.push(r);
			return arr;
		}

		public function getRewardInstanceById(id:int):RewardInstanceDef
		{
			return _rewards[id];
		}

		public function addRewardInstance(reward:RewardInstanceDef):void
		{
			_rewards[reward.id] = reward;
		}

		public function get uid():String
		{
			return socialUser.id;
		}

		public function getRoll():Number
		{
			throw new Error('GameUser not implemented getRoll');
		}

		public function setRoll(roll:uint):void
		{
			throw new Error('GameUser not implemented setRoll');
		}

		public function clearLevelInstances():void
		{
			_levelInstances = [];
		}

		public function clearRewards():void
		{
			_rewards = [];
		}
	}
}