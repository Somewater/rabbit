package com.somewater.rabbit.storage
{
	import com.somewater.social.SocialUser;
	import com.somewater.storage.InfoDef;

	public class GameUser extends InfoDef implements IGameUser {
		protected var _socialUser:SocialUser;
		
		protected var _score:int;
		protected var _stars:int;
		protected var _levelInstances:Array = [];
		protected var _rewards:Array = [];
		protected var _offerInstances:Array = [];
		protected var _postings:int;
		protected var _friendsInvited:int;
		protected var _customize:Array = [];
		private var _levelNumber:int;
		
		public function GameUser(data:Object = null)
		{
			this.supressSerializationWarn = true;
			super(data)
		}

		public function itsMe():Boolean {
			return false;
		}

		override public function set data(value:Object):void
		{
			if(value is SocialUser)
				this._socialUser = value as SocialUser;
			else if(value)
			{
				if(value.hasOwnProperty('level'))
					this._levelNumber = value['level'];
				if (value.hasOwnProperty('friends_invited'))
					this._friendsInvited = value['friends_invited'];
				super.data = value;
			}
		}

		public function get socialUser():SocialUser
		{
			return _socialUser;
		}

		/**
		 * Должен обеспечивать перезаписывание старого значения новым
		 * @param levelInst
		 */
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

		public function set stars(value:int):void
		{
			_stars = value;
		}
		public function get stars():int
		{
			return _stars;
		}

		/**
		 * Максимальный numner, который прошел юзер (фактически Левел юзера)
		 */
		public function get levelNumber():int
		{
			return _levelNumber;
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

		public function addOfferInstance(offer:OfferDef):void
		{
			if(_offerInstances[offer.id] != null)
				throw new Error('Offer already added')
			_offerInstances[offer.id] = offer;
		}

		public function getOfferInstanceById(id:int):OfferDef
		{
			return _offerInstances[id];
		}

		public function removeOfferInstanceById(id:int):void
		{
			delete(_offerInstances[id]);
		}

		public function get uid():String {
			return socialUser.id;
		}

		public function getRoll():Number
		{
			throw new Error('GameUser not implemented getRoll');
		}

		public function setRoll(roll:uint):void
		{
			//throw new Error('GameUser not implemented setRoll');
		}

		public function clearLevelInstances():void
		{
			_levelInstances = [];
		}

		public function clearRewards():void
		{
			_rewards = [];
		}

		public function clearOfferInstances():void
		{
			_offerInstances = [];
		}

		public function set postings(postings:int):void {
			_postings = postings;
		}

		public function get postings():int
		{
			return _postings;
		}

		public function get friendsInvited():int
		{
			return _friendsInvited;
		}

		public function addAppFriend(gameUserFriend:GameUser):void
		{
			throw new Error('GameUser not implemented addAppFriend');
		}

		public function clearCustomize():void
		{
			_customize = [];
		}

		public function getCustomize(type:String):CustomizeDef
		{
			return CustomizeDef.byId(_customize[type]);
		}

		public function setCustomize(customize:CustomizeDef):void
		{
			_customize[customize.type] = customize.id;
		}
	}
}