package com.somewater.rabbit.loader{
	import com.google.analytics.GATracker;
	import com.somewater.arrow.ArrowPermission;
	import com.somewater.arrow.IArrow;
	import com.somewater.net.ServerHandler;
	import com.somewater.rabbit.Stat;
	import com.somewater.rabbit.storage.Config;
	import com.somewater.social.SocialUser;

	import flash.net.URLRequest;
	import flash.net.navigateToURL;

	/**
	 * Базовый лоадер для создания социал адаптеров
	 */
	[SWF(width="810", height="650", backgroundColor="#FFFFFF", frameRate="30")]
	public class SocialRabbitLoader extends RabbitLoaderBase{

		protected var arrow:IArrow;

		public function SocialRabbitLoader() {
			super();
		}

		protected function onArrowComplete(key:String):void
		{
			try
			{
				arrow.init({'stage': this, 'complete':onNetInitializeComplete, 'error':onNetInitializeError, 'key':key});
			}catch(error:Error)
			{
				trace(error + "\n" + error.getStackTrace());
			}
		}

		override protected function initializeServerHandler():void
		{
			_serverHandler = new ServerHandler();
			_serverHandler.init(getUser().id, arrow.key, net);
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
			return arrow.getFriends()
		}

		override public function getAppFriends():Array
		{
			return arrow.getAppFriends();
		}

		override public function getUser():SocialUser
		{
			return arrow.getUser();
		}

		override public function setUser(user:SocialUser):void {
			// nothing
		}

		override public function showInviteWindow():void
		{
			arrow.showInviteWindow();
			Config.stat(Stat.FRIENDS_INVITED);
		}

		override public function pay(quantity:Object, onSuccess:Function, onFailure:Function, params:Object = null):void
		{
			arrow.pay(quantity, onSuccess, onFailure, params);
		}

		override public function getUsers(uids:Array, onComplete:Function, onError:Function):void
		{
			arrow.getUsers(uids, onComplete, onError);
		}

		override public function canPost(type:String = null):Boolean
		{
			if(type == null || type == arrow.getUser().id)
				return (arrow.hasPermissions & ArrowPermission.STREAM_POST) != 0;
			else
				return (arrow.hasPermissions & ArrowPermission.WALL_POST) != 0;
		}

		override public function posting(user:SocialUser = null, title:String = null, message:String = null, image:* = null, imageUrl:String = null, data:String = null, onComplete:Function = null, onError:Function = null, additionParams:Object = null):void {
			arrow.posting(user, title, message, image, imageUrl, data, onComplete, onError, additionParams);
		}

		override public function getCachedUser(uid:String):SocialUser {
			return arrow.getCachedUser(uid);
		}

		override public function navigateToHomePage(userId:String):void {
			if(hasNavigateToHomepage)
			{
				var u:SocialUser = getCachedUser(userId);
				if(u && u.homepage)
					navigateToURL(new URLRequest(u.homepage), '_blank');
			}
		}
	}
}
