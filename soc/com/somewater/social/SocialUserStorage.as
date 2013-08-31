package com.somewater.social {
	public class SocialUserStorage implements ISocialUserStorage {

		protected var usersById:Array = [];
		protected var friendsById:Array = [];
		protected var appFriendsById:Array = [];
		protected var me:SocialUser;

		public function SocialUserStorage() {
		}

		public function addSocialUser(user:SocialUser):void {
			if (user.itsMe)
				me = user;
			if (user.isFriend)
				friendsById[user.id] = user;
			if (user.isAppFriend)
				appFriendsById[user.id] = user;
			usersById[user.id] = user;
		}

		public function getFriends():Array {
			var arr:Array = [];
			for each(var f:SocialUser in friendsById)
				arr.push(f);
			return arr;
		}

		public function getAppFriends():Array {
			var arr:Array = [];
			for each(var f:SocialUser in appFriendsById)
				arr.push(f);
			return arr;
		}

		public function getPlayer():SocialUser {
			return me;
		}

		public function getUsers(uids:Array):Array {
			var result:Array = [];
			for (var i:int = 0; i < uids.length; i++)
				if (usersById[uids[i]] != null) {
					result.push(usersById[uids[i]]);
				}
			return result;
		}

		public function getUsersById(id:String):SocialUser {
			return usersById[id];
		}
	}
}
