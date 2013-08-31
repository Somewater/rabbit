package com.somewater.social {
	public interface ISocialUserStorage {
		function addSocialUser(user:SocialUser):void;

		function getFriends():Array;

		function getAppFriends():Array;

		function getPlayer():SocialUser;

		function getUsers(uids:Array):Array;

		function getUsersById(id:String):SocialUser;
	}
}
