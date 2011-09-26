package com.somewater.social
{
	public class LocalSocialAdapter extends SocialAdapter
	{
		public function LocalSocialAdapter()
		{
			super();
		}
		
		override public function get networkId():int
		{
			return 0;
		}
		
		override protected function _isAppUser():Boolean
		{
			return true;
		}
		
		override public function loadUserProfile(onComplete:Function, onError:Function=null):void
		{
			onComplete({"first_name":"Иван", "last_name":"Кузьмич","uid":777,"sex":1})
		}
		
		override public function loadUserFriendsProfiles(onComplete:Function, onError:Function=null):void
		{
			onComplete([{"first_name":"Евгений", "last_name":"Антипов","uid":1000,"sex":1}
						, {"first_name":"Степан", "last_name":"Самойлов","uid":1001,"sex":1}
						, {"first_name":"Иннокентий", "last_name":"Кудрявцев","uid":1002,"sex":1}
						, {"first_name":"Анжелика", "last_name":"Протопопова","uid":1003,"sex":2}
						, {"first_name":"Екатерина", "last_name":"Красноносова","uid":1004,"sex":2}
						, {"first_name":"Светлана", "last_name":"Павлицкая","uid":1005,"sex":2}
					  ]);
		}
		
		override public function loadUserAppFriends(onComplete:Function, onError:Function=null):void
		{
			onComplete(["1000","1002","1005"]);
		}
		
		
		override public function createSocialUser(info:Object):SocialUser
		{
			var socialUser:SocialUser = new SocialUser();
			socialUser.id = info["uid"];
			socialUser.firstName = info["first_name"];
			socialUser.lastName = info["last_name"];
			socialUser.nickName = info["nickname"];
			socialUser.male = info["sex"]!=1;
			socialUser.city = info['city']?info['city']:null;		
			socialUser.country = info['country']?info['country']:null;
			socialUser.photos = [info["photo"],info["photo_medium"],info["photo_big"]];
			return socialUser;
		}
		
		override public function get user_id():String
		{
			return user?user.id:"777";
		}
		
		override public function get authentication_key():String
		{
			return "auth_1234567890_auth";
		}
	}
}