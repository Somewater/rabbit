package com.somewater.arrow {
	import com.adobe.crypto.MD5;
	import com.adobe.serialization.json.JSON;
	import com.somewater.social.SocialUser;
	import com.somewater.storage.HashModem;

	import flash.events.Event;
	import flash.external.ExternalInterface;

	import flash.net.URLVariables;
	import flash.system.Security;
	import flash.utils.Dictionary;

	public class ArrowMailru extends ArrowBase{

		/**
		 * Которые стоят изначально (т.е. без проставления пермишнов)
		 */
		private const DEFAULT_PERMISSIONS:uint = ArrowPermission.FRIENDS_PROFILES
												| ArrowPermission.PAYMENT
												| ArrowPermission.STREAM_POST
												| ArrowPermission.USER_PROFILE
												| ArrowPermission.WALL_POST;

		public static const EVENT_LOCATION_CHANGED:String = 'eventLocationChanged';

		public var location:String;

		public function ArrowMailru() {
			super();
			permissions = DEFAULT_PERMISSIONS;
		}

		override public function get hasPermissions():uint {
			return ArrowPermission.FRIENDS_PROFILES |
					ArrowPermission.NOTIFY |
					ArrowPermission.PAYMENT |
					ArrowPermission.STREAM_POST |
					ArrowPermission.USER_PROFILE |
					ArrowPermission.WALL_POST;
		}

		override public function get key():String {
			return flashVars["authentication_key"];
		}

		private function onLocationChanged(e:MailruCallEvent):void
		{
			if(e.data == null || e.data == "" || e.data[""] == "") return;
			if(e.data["loc"])
				location = e.data["loc"];
			else
				location = JSON.encode(e.data);
			dispatchEvent(new ArrowEvent(ArrowEvent.LOCATION_CHANGED));
		}

		override public function showInviteWindow():void {
			if(MailruCall.isInited)
				MailruCall.exec("mailru.app.friends.invite");
		}

		/**
		 *
		 * @param quantity
		 * @param onSuccess
		 * @param onFailure
		 * @param params
		 * 			code
		 * 			to_rubles [optional]
		 */
		override public function pay(quantity:Object, onSuccess:Function, onFailure:Function, params:Object = null):void {
			var socialMoney:int = int(quantity);
			params ||= {}
			var code:String = params['code'];
			if(!code || code.length == 0)
				throw new Error('Need payment code params[code]');
			var title:String = params['title'];
			if(MailruCall.isInited){

				var paymentParams:Object = {
					"service_id": code,
				    "service_name": title,
				    "sms_price": socialMoney
				}

				if(params){
					if(params["other_price"])
						paymentParams["other_price"] = params["other_price"];
					if(params["other_price_only"])
						delete paymentParams["sms_price"];
				}

				if( !paymentParams["other_price"] ){
					paymentParams["other_price"] = 100 * socialMoney*(params['to_rubles'] ? params['to_rubles'] : 30);//TODO
				}

				if(onSuccess != null){
					MailruCall.addEventListener("app.incomingPayment", incomingPayment);
					MailruCall.addEventListener("app.paymentDialogStatus", paymentDialogStatus);
				}
				MailruCall.exec("mailru.app.payments.showDialog", null, paymentParams);
			}

			function incomingPayment(e:MailruCallEvent):void{
				if(e.data.status == "success"){
					onSuccess();
				}
				clearListeners();
			}
			function paymentDialogStatus(e:MailruCallEvent):void{
				if(e.data.status != "opened"){
					clearListeners();
				}
			}
			function clearListeners():void{
				MailruCall.removeEventListener("app.incomingPayment", incomingPayment);
				MailruCall.removeEventListener("app.paymentDialogStatus", paymentDialogStatus);
			}
		}

		override public function posting(user:SocialUser = null, title:String = null, message:String = null, image:* = null, imageUrl:String = null, data:String = null, onComplete:Function = null, onError:Function = null, additionParams:Object = null):void {
			if(!user)
				user = getUser();
			var stream:Boolean = user.itsMe && (permissions & ArrowPermission.STREAM_POST);// если это постинг самому игроку и stream разрешен, то постим stream. Иначе в гостевую книгу

			var publishListenerName:String = (stream?"common.streamPublish":"common.guestbookPublish");

			if(title) title = title.replace(/\"/g,"''");
			if(title) title = (title.length >  400?title.substr(0, 397) + "...":title);
			if(message) message = message.replace(/\"/g,"''");
			if(message) message = (message.length >  400?message.substr(0, 397) + "...":message);


			var argData:Object = {
				"title": title,
				"text": message,
				"img_url": imageUrl//120px × 60px (stream)  или  420px × 280px (guestbook)
			};
			if(!stream) argData["uid"] = user.id;

			if(!additionParams)	additionParams = {};
			if(!additionParams["linkText"] && additionParams["playTo"])
				additionParams["linkText"] = additionParams["playTo"];
			if(!additionParams["linkText"] && additionParams["name"])
				additionParams["linkText"] = additionParams["name"];
			if(!additionParams["linkText"])
				additionParams["linkText"] = "Играть";



			// очистить все текстовые поля от символа "


			additionParams["linkText"] = additionParams["linkText"].replace(/\"/g,"''");
			additionParams["linkText"] = (additionParams["linkText"].length >  20?additionParams["linkText"].substr(0, 17) + "...":additionParams["linkText"]);


			argData["action_links"] = [{"text": additionParams["linkText"], "href": "loc=" + data}];

			if(additionParams["linkText2"])
				argData["action_links"].push({"text": additionParams["linkText2"], "href": "loc=" +
					(additionParams["postData2"]?additionParams["postData2"]:data)});

			MailruCall.addEventListener(publishListenerName, function(e:MailruCallEvent):void{
				if(e.data.status == "publishSuccess"){
					onComplete && onComplete();
					MailruCall.removeEventListener(publishListenerName, arguments.callee);
				}else if(e.data.status == "authError" || e.data.status == "closed" || e.data.status == "publishFail"){
					onError && onError();
					MailruCall.removeEventListener(publishListenerName, arguments.callee);
				}
			});
			var postMethod:String = stream?"mailru.common.stream.publish":"mailru.common.guestbook.publish";
			MailruCall.exec(postMethod, null, argData);
			MailruCall.createLastCallback(postMethod, argData);// запоминаем параметры запроса, чтобы восстановить их на случай логирования ошибки api
		}

		override public function setPermissions(required:uint = 0):void {
			if(!required)
				required = ArrowPermission.DEFAULT
			if(MailruCall.isInited)
			{
				// удалить листенеры, на случай, если они ранее уже были установлены
				MailruCall.removeEventListener("app.permissionDialogStatus", onSettingsChanged);
				MailruCall.removeEventListener("common.permissionChanged", onSettingsChanged);

				MailruCall.addEventListener("app.permissionDialogStatus", onSettingsChanged);// на ответ о неудаче или открытии окна
				MailruCall.addEventListener("common.permissionChanged", onSettingsChanged);// на ответ об изменении настроек
            	MailruCall.exec("mailru.common.users.requirePermission",null,getStringPermissions(required, false));
			}
		}

		private function onSettingsChanged(e:MailruCallEvent):void{
			if(e.data.status == "success"){
				if(e.data.permissionType){
					flashVars["ext_perm"] = e.data.permissionType;
					parcePermissions();
				}
				// удалить листенеры, т.к. они более не нужны
				MailruCall.removeEventListener("app.permissionDialogStatus", onSettingsChanged);
				MailruCall.removeEventListener("common.permissionChanged", onSettingsChanged);

				dispatchEvent(new ArrowEvent(ArrowEvent.PERMISSION_CHANGED));
			}
		}

		protected function getStringPermissions(permissions:uint, asArray:Boolean):*{
			var permissionsArray:Array = [];
			if(ArrowPermission.NOTIFY & permissions) permissionsArray.push("notification");
			if(ArrowPermission.STREAM_POST & permissions) permissionsArray.push("stream");
			//if(ArrowPermission & permissions) permissionsArray.push("widget");

			if(asArray)
				return permissionsArray;
			else
				return permissionsArray.join();
		}

		override public function installApp(requredPermissions:uint = 0):void {
			if(!requredPermissions)
				requredPermissions = ArrowPermission.DEFAULT
			if(MailruCall.isInited){
				MailruCall.addEventListener("app.applicationInstallation", function(e: MailruCallEvent):void{
					MailruCall.removeEventListener("app.applicationInstallation", arguments.callee);
					if(e.data.status == "success"){
						flashVars["is_app_user"] = 1;
						if(e.data.permissionType){
							flashVars["ext_perm"] = e.data.permissionType;
							parcePermissions();
						}
						dispatchEvent(new ArrowEvent(ArrowEvent.APP_INSTALLED));
					}
				});
				MailruCall.exec("mailru.app.users.requireInstallation",null, getStringPermissions(requredPermissions, true));
			}
		}

		override public function get netId():int
		{
			return 2;
		}

		//////////////////////////////////
		//                              //
		//		P R O T E C T E D		//
		//                              //
		//////////////////////////////////

		/**
		 * Установить соединение с API
		 * (например, LC с враппером)
		 */
		override protected function connectToApi():void
		{
			if(!MailruCall.isInited){
				Security.allowDomain ( '*' );
				MailruCall.init("flash-app", initParams['key']);
				MailruCall.addEventListener(Event.COMPLETE, onMailruCallComplete);
			}else
				refresh();
		}

		/**
		 * Перевести настройки в стиле мейл.ру "настройка1,настройка2,настройка3" в битовые маски переменной PERMISSIONS
		 */
		protected function parcePermissions():void{
			var lastPerm:int = permissions;// сохранить старое значение
			permissions = DEFAULT_PERMISSIONS;// функции соц. сети с маской "1" работают всегда

			// если в новых настройках разрешена "notification" или она уже была выставлена ранее
			// (mail api не возвращает старые настройки, а лишь те, которые были добавлены в данный момент)
			if(flashVars["ext_perm"].indexOf("notification") != -1 || (lastPerm & ArrowPermission.NOTIFY))
				permissions |= ArrowPermission.NOTIFY;

			if(flashVars["ext_perm"].indexOf("stream") != -1)
				permissions |= ArrowPermission.STREAM_POST;

			if(flashVars["ext_perm"].indexOf("widget") != -1)
				permissions |= 0;// TODO
		}

		protected function onMailruCallComplete(e:Event):void{
			MailruCall.removeEventListener(Event.COMPLETE, onMailruCallComplete);
			MailruCall.addEventListener('app.readHash', onLocationChanged);
            MailruCall.exec('mailru.app.utils.hash.read', onLocationChanged);
			parcePermissions();
			refresh();
		}

		override protected function startInitLoading():void{
			MailruCall.exec("mailru.common.users.getInfo", function(e:Object):void{
				initData["user"] = e[0];
				checkInitLoadingCompletion();
			});
			MailruCall.exec("mailru.common.friends.getExtended", function(e:Object):void{
				initData["friends"] = e;
				checkInitLoadingCompletion();
			});
			MailruCall.exec("mailru.common.friends.getAppUsers", function(e:Object):void{
				initData["appFriends"] = e;
				checkInitLoadingCompletion();
			});
		}

		/**
		 * Действительно обратиться к соц сети за профайлами
		 */
		override protected function getUserProfiles(uids:Array, onComplete:Function, onError:Function):void
		{
			var received:Array = [];

			if(uids.length)
				getNextProfiles();
			else
				onInnerComplete();

			function getNextProfiles():void{
				MailruCall.exec("mailru.common.users.getInfo", onInnerComplete, uids.splice(0, Math.min(80, uids.length)));
			}

			function onInnerComplete(response:Array = null):void{
				if(response)
					received = received.concat(response);

				if(uids.length){
					getNextProfiles();
				}else{
					var event:ArrowEvent = new ArrowEvent(ArrowEvent.REQUEST_SUCCESS);
					event.response = received;
					onComplete(event);
				}
			}
		}

		/**
		 * Сериализовать объект в данные соц. сети
		 */
		override protected function createSocialUser(info:Object):SocialUser
		{
			var socialUser:SocialUser = new SocialUser();
			socialUser.id = info["uid"];
			socialUser.firstName = info["first_name"];
			socialUser.lastName = info["last_name"];
			socialUser.male = (info["sex"] != 1);
			socialUser.homepage = info['link'];
			if( !info["pic_medium"] ) info["pic_medium"] = info["pic"];
			if( !info["pic_big"] ) info["pic_big"] = info["pic_medium"];
			socialUser.photos = [info["pic"], info["pic_medium"], info["pic_big"]];
			if(info["birthday"]){
				var a:Array = info["birthday"].split(".");
				var d:Date = new Date(Number(a[2] == null?new Date().fullYear:a[2]), Number(a[1]) - 1, Number(a[0]));
				socialUser.birthday = d;
			}
			return socialUser;
		}

		override protected function getApiPath(method:String, params:Object, flags:Object):String
		{
			return flashVars["api_url"] ? flashVars["api_url"] : "http://api.vkontakte.ru/api.php";
		}

		override protected function appInstalled():Boolean{
			return flashVars["is_app_user"] == 1;
		}
	}
}

import com.adobe.serialization.json.JSON;

import flash.events.Event;
import flash.events.EventDispatcher;
import flash.external.ExternalInterface;

internal class MailruCallEvent extends Event {

	static public var PERMISSIONS_CHANGED   : String = 'common.permissionChanged';
	static public var FRIENDS_INVITATION    : String = 'app.friendsInvitation';
	static public var REVIEW                : String = 'app.review';
	static public var INCOMING_PAYMENT      : String = 'app.incomingPayment';
	static public var PAYMENT_DIALOG_STATUS : String = 'app.paymentDialogStatus';
	static public var ALBUM_CREATED         : String = 'common.createAlbum';
	static public var GUESTBOOK_PUBLISH     : String = 'common.guestbookPublish';
	static public var STREAM_PUBLISH        : String = 'common.streamPublish';

	public var data : Object;

	public function MailruCallEvent ( type : String, data : Object ) {
		super ( type );
		this.data = data;
	}

	override public function clone (  ) : Event {
		return new MailruCallEvent ( type, data ) as Event;
	}

}

internal class MailruCall	{

	static private var callbacks     : Object = {};
	static private var flashId       : String;
	static private var appPrivateKey : String;
	static private var dispatcher    : EventDispatcher = new  EventDispatcher();
	static public var isInited       : Boolean = false;
	static private var isApiInited	 : Boolean = false;

	/**
	 * хардкод, запоминаем параметры последнего запроса, осуществляющего постинг
	 */
	private static var lastCallback:CallbackInfo;
	public static function createLastCallback(method:String, args:Object):void
	{
		lastCallback = new CallbackInfo(0, null, method, args);
	}

	static public function init ( DOMFlashId : String, privateKey : String ) : void {
		if ( isInited ) { throw Error ( 'MailruCall already initialized' ); return; }
		flashId = DOMFlashId;
		appPrivateKey = privateKey;
		ExternalInterface.addCallback('mailruReceive', receiver);
		exec ( 'mailru.init', onApiLoaded, privateKey, flashId );
		isInited = true;
	}

		/** Если callback не указан, exec() попытается вернуть значение **/
	static public function exec ( method : String, callback : Function = null, ...args ) : * {
		lastCallback = null;
		var cbid : int;
		if ( callback != null ) {
			cbid = Math.round ( Math.random() * int.MAX_VALUE );
			callbacks[cbid] = new CallbackInfo(cbid, callback, method, args);
		}
		var objectName:String = (method.match(/(.*)\.[^.]+$/)||[0,'window'])[1];
		return ExternalInterface.call('' +
			'(function(args, cbid){ ' +
			'if(typeof ' + method + ' != "function"){ ' +
			'	if(cbid) { document.getElementById("'+ flashId+ '").mailruReceive(cbid, ' + method + '); }' +
			'	else { return '+ method+ '; }' +
			'}' +
			'if(cbid) {' +
			'	args.unshift(function(value){ ' +
			'		document.getElementById("'+ flashId+ '").mailruReceive(cbid, value) ' +
			'	}); ' +
			'};' +
			'return '+ method+ '.apply('+ objectName+ ', args) ' +
			'})', args, cbid);
	}

	static private function receiver ( cbid : Number, data : Object ) : void {
		if ( callbacks[cbid] ) {
			var cbInfo:CallbackInfo = callbacks[cbid];
			var cb : Function = cbInfo.callback;
			delete callbacks[cbid];

			// TODO: распознать, что сервер ответил что то невалидное и обработать в сошл. адаптере как logError
			// как узнать факт ошибки - хз, зависит от того, что ждет запрос
			// Стандартного формата ошибок на данный момент не описано

			cb.call ( null, data );
		}
	}

	static private function eventReceiver ( name : String, data : Object ) : void {
		trace("new Event name:" + name + ", data:" + JSON.encode(data));

		if(data && data.hasOwnProperty("status") && String(data.status).search(/(error|fail)/i) != -1)
		{
			// обработать как ошибку api
			if(lastCallback)
			{
				lastCallback = null;
			}else{
			}
		}

		dispatchEvent ( new MailruCallEvent ( name, data ) );
	}

	static private function onApiLoaded ( ...args ) : void {
		isApiInited = true;
		ExternalInterface.addCallback ( 'mailruEvent', eventReceiver );
		dispatchEvent ( new Event ( Event.COMPLETE ) );
	}

	/************************* EventDispatcher IMPLEMENTATION ****************************/

	static public function addEventListener ( type : String, listener : Function, priority : int = 0, useWeakReference : Boolean = false ) : void {
   		dispatcher.addEventListener ( type, listener, false, priority, useWeakReference );
	}

	static public function removeEventListener ( type : String, listener : Function ) : void {
		dispatcher.removeEventListener ( type, listener );
	}

	static public function hasEventListener ( type : String ) : Boolean {
		return dispatcher.hasEventListener ( type );
	}

	static public function dispatchEvent ( event : Event ) : void {
		dispatcher.dispatchEvent ( event );
	}

}

class CallbackInfo
{
	public var cbid:int;
	public var callback:Function;
	public var method:String;
	public var args:Object;

	public function CallbackInfo(cbid:int, callback:Function, method:String, args:Object)
	{
		this.cbid = cbid;
		this.callback = callback;
		this.method = method;
		this.args = args;
	}
}
