package com.somewater.social {
	public interface ISocialUserStorage {
		function addSocialUser(user:SocialUser):void;

		function getFriends():Array;

		function getAppFriends():Array;

		function getUser():SocialUser;

		function getUsers(uids:Array):Array;
	}
}
