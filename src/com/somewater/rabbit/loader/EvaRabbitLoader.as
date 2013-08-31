package com.somewater.rabbit.loader {
	import com.somewater.arrow.ArrowPermission;
	import com.somewater.net.ServerHandler;
	import com.somewater.rabbit.Stat;
	import com.somewater.rabbit.storage.Config;
	import com.somewater.social.ISocialUserStorage;
	import com.somewater.social.SocialUser;
	import com.somewater.social.SocialUserStorage;

	import flash.net.URLRequest;
	import flash.net.navigateToURL;

	import ru.evast.integration.IntegrationProxy;
	import ru.evast.integration.core.SocialNetworkTypes;
	import ru.evast.integration.core.SocialProfileVO;

	public class EvaRabbitLoader extends RabbitLoaderBase{

		protected var arrow:Object;
		protected var userStorage:ISocialUserStorage;

		public function EvaRabbitLoader() {
			super();
		}

		override protected function netInitialize():void {
			if(arrow && arrow is ISocialUserStorage)
				userStorage = arrow as ISocialUserStorage;
			else
				userStorage = new SocialUserStorage();

			var appFriendIds:Array;
			var friends:Array;
			var user:SocialProfileVO;

			IntegrationProxy.adapter.GetFriends(false, function(response:Object){
				trace("[EVA API] GetFriends");
				friends = response as Array;
				parseEvaInitData(user, friends, appFriendIds);
			})
			IntegrationProxy.adapter.GetAppFriends(true, function(response:Object){
				trace("[EVA API] GetAppFriends");
				appFriendIds = response as Array;
				parseEvaInitData(user, friends, appFriendIds);
			})
			IntegrationProxy.batchLoadProfiles(IntegrationProxy.adapter.Me(), function(response:Object){
				trace("[EVA API] batchLoadProfiles");
				user = response[0] as SocialProfileVO;
				parseEvaInitData(user, friends, appFriendIds);
			})
		}

		private function parseEvaInitData(user:SocialProfileVO, friends:Array, appFriendIds:Array):void {
			if(user && friends && appFriendIds){
				var appUserIdsHash:Object = {};
				var id:String;
				var s:SocialProfileVO;
				var su:SocialUser;

				su = SocialProfileVOToSocialUser(user);
				su.itsMe = true;
				userStorage.addSocialUser(su);

				for each(id in appFriendIds)
					appUserIdsHash[id] = true;

				for each(s in friends){
					su = SocialProfileVOToSocialUser(s);
					su.isFriend = true;
					su.isAppFriend = appUserIdsHash[su.id];
					userStorage.addSocialUser(su);
				}

				onNetInitializeComplete();
			}
		}

		private function SocialProfileVOToSocialUser(s:SocialProfileVO):SocialUser {
			var su:SocialUser = new SocialUser();
			su.id = s.Uid;
			su.firstName = s.FirstName;
			su.lastName = s.LastName;
			su.photos = [s.PicSmall, s.PicMedium, s.PicBig];
			if(s.BirthDate && s.BirthDate.split(".").length == 3){
				var a:Array = s.BirthDate.split(".");
				var d:Date = new Date(Number(a[2] == null?new Date().fullYear:a[2]), Number(a[1]) - 1, Number(a[0]));
				su.birthday = d;
			}
			su.city = s.City;
			su.country = s.Country;
			su.homepage = s.UrlProfile;
			su.male = s.isMan;
			return su;
		}

		override protected function initializeServerHandler():void
		{
			_serverHandler = new ServerHandler();
			_serverHandler.init(IntegrationProxy.adapter.Me(), IntegrationProxy.adapter.GetAuthData(), net);
		}

		override public function get flashVars():Object {
			if(arrow && arrow.flashVars)
				return arrow.flashVars
			else
				return super.flashVars;
		}

		override public function get hasUserApi():Boolean { return true; }

		override public function get hasUsersApi():Boolean { return true; }

		override public function get hasFriendsApi():Boolean { return true; }

		override public function getFriends():Array
		{
			return userStorage.getFriends()
		}

		override public function getAppFriends():Array
		{
			return userStorage.getAppFriends();
		}

		override public function getUser():SocialUser
		{
			return userStorage.getUser();
		}

		override public function setUser(user:SocialUser):void {
			// nothing
		}

		override public function showInviteWindow():void
		{
			//arrow.showInviteWindow();
			IntegrationProxy.adapter.InviteFriends(Config.application.translate('INVITE_FRIENDS_API_WND'));
			Config.stat(Stat.FRIENDS_INVITED);
		}

		override public function pay(quantity:Object, onSuccess:Function, onFailure:Function, params:Object = null):void
		{
			//arrow.pay(quantity, onSuccess, onFailure, params);
			// TODO 1
		}

		override public function getUsers(uids:Array, onComplete:Function, onError:Function):void
		{
			//arrow.getUsers(uids, onComplete, onError);
			// TODO 2
		}

		override public function canPost(type:String = null):Boolean
		{
			if(arrow){
				if(type == null || type == arrow.getUser().id)
					return (arrow.hasPermissions & ArrowPermission.STREAM_POST) != 0;
				else
					return (arrow.hasPermissions & ArrowPermission.WALL_POST) != 0;
			} else {
				return true;
			}
		}

		override public function posting(user:SocialUser = null, title:String = null, message:String = null, image:* = null, imageUrl:String = null, data:String = null, onComplete:Function = null, onError:Function = null, additionParams:Object = null):void {
			//arrow.posting(user, title, message, image, imageUrl, data, onComplete, onError, additionParams);
			if(!user || user.itsMe){
				IntegrationProxy.adapter.PostToWall(message, imageUrl);
			} else {
				IntegrationProxy.adapter.SendNotification(message, user.id, imageUrl);
			}
		}

		override public function getCachedUser(uid:String):SocialUser {
			return userStorage.getUsers([uid])[0];
		}

		override public function navigateToHomePage(userId:String):void {
			if(hasNavigateToHomepage)
			{
				var u:SocialUser = getCachedUser(userId);
				if(u && u.homepage)
					navigateToURL(new URLRequest(u.homepage), '_blank');
			}
		}

		override public function get referer():String {
			return IntegrationProxy.adapter.GetReferalId();
		}
	}
}
