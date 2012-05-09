package com.somewater.arrow {
	import com.somewater.social.SocialUser;

	import flash.events.IEventDispatcher;

	public interface IArrow extends IEventDispatcher{
		function get flashVars():Object;

		function get key():String;

		/**
		 * @param params {stage, complete, error, key}
		 */
		function init(params:Object):void;

		function get hasUserApi():Boolean;

		function get hasFriendsApi():Boolean;

		function get hasPaymentApi():Boolean;

		function getFriends():Array;

		function getAppFriends():Array;

		function getUser():SocialUser;

		function showInviteWindow():void;

		/**
		 * @param required если не задано, запросить настройки по умолчанию (нотифай и доступ к друзьям)
		 */
		function setPermissions(required:uint = 0):void

		/**
		 * Какие пермишны в принципе можно выставить в этой соц. сети
		 */
		function get hasPermissions():uint

		/**
		 * @param requredPermissions если не задан, запросить настройки по умолчанию
		 */
		function installApp(requredPermissions:uint = 0):void

		/**
		 *
		 * @param quantity
		 * @param onSuccess
		 * @param onFailure
		 * @param params {title, message, code, ...}
		 */
		function pay(quantity:Object,
					 onSuccess:Function,
					 onError:Function,
					 params:Object = null):void;

		function getUsers(uids:Array,
						  onComplete:Function,
						  onError:Function):void;

		function posting(user:SocialUser = null,
						 title:String = null,
						 message:String = null,
						 image:* = null,
						 imageUrl:String = null,
						 data:String = null,
						 onComplete:Function = null,
						 onError:Function = null,
						 additionParams:Object = null):void;

		function getCachedUser(uid:String):SocialUser;

		function call(method:String,
					  params:Object = null,
					  onComplete:Function = null,
					  onError:Function = null,
					  flags:Object = null):void

		/**
		 * Идентификатор соц. сети
		 * 1 - тестовая флешка
		 * 2 - вконтакт
		 * 3 - mailru
		 */
		function get netId():int;

		function jsonDecode(string:String):Object

		function jsonEncode(object:Object):String
	}
}
