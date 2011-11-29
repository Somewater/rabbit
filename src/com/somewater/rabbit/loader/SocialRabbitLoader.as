package com.somewater.rabbit.loader{
	import com.somewater.net.ServerHandler;
	import com.somewater.social.SocialUser;

	/**
	 * Базовый лоадер для создания социал адаптеров
	 */
	[SWF(width="810", height="650", backgroundColor="#FFFFFF", frameRate="30")]
	public class SocialRabbitLoader extends RabbitLoaderBase{

		protected var arrow:*;

		public function SocialRabbitLoader() {
			super();
		}

		override protected function initializeServerHandler():void
		{
			_serverHandler = new ServerHandler();
			_serverHandler.init(getUser().id, 'embed', net);
		}

		override public function get flashVars():Object {
			if(arrow && arrow.flashVars)
				return arrow.flashVars
			else
				return super.flashVars;
		}

		override public function get hasUserApi():Boolean { return true; }

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

		override public function showInviteWindow():void
		{
			arrow.showInviteWindow();
		}

		override public function pay(quantity:Object, onSuccess:Function, onFailure:Function, params:Object = null):void
		{
			arrow.pay(quantity, onSuccess, onFailure, params);
		}

		override public function getUsers(uids:Array, onComplete:Function, onError:Function):void
		{
			arrow.getUsers(uids, onComplete, onError);
		}


		override public function posting(user:SocialUser = null, title:String = null, message:String = null, image:* = null, imageUrl:String = null, data:String = null, onComplete:Function = null, onError:Function = null, additionParams:Object = null):void {
			arrow.posting(user, title, message, image, imageUrl, data, onComplete, onError, additionParams);
		}
	}
}