package com.somewater.arrow {
	import com.adobe.crypto.MD5;
	import com.adobe.serialization.json.JSON;
	import com.somewater.social.SocialUser;
	import com.somewater.storage.HashModem;

	import flash.events.Event;
	import flash.external.ExternalInterface;

	import flash.net.URLVariables;
	import flash.utils.Dictionary;
	import flash.utils.getTimer;

	public class ArrowVkcom extends ArrowBase{

		/**
		 * Которые стоят изначально (т.е. без проставления пермишнов)
		 */
		private const DEFAULT_PERMISSIONS:uint =  ArrowPermission.PAYMENT
												//| ArrowPermission.STREAM_POST
												| ArrowPermission.USER_PROFILE
												| ArrowPermission.WALL_POST;

		private var VK:APIConnection;
		public var location:String;
		public var balance:Number = 0;

		protected var balanceLoading:Boolean = false;// происходит перезагрузка баланса (нельзя вызывать окно, так как пока что не извесне баланс узера)

		public function ArrowVkcom() {
			super();
			permissions = DEFAULT_PERMISSIONS;
		}

		override public function get hasPermissions():uint {
			return ArrowPermission.FRIENDS_PROFILES |
					ArrowPermission.NOTIFY |
					ArrowPermission.PAYMENT |
					//ArrowPermission.STREAM_POST |
					ArrowPermission.USER_PROFILE |
					ArrowPermission.WALL_POST;
		}

		override public function get key():String {
			return flashVars["auth_key"];
		}

		override public function init(params:Object):void {
			params['autoStart'] = false;
			super.init(params);

			try {
				if(ExternalInterface.available)
					ExternalInterface.addCallback("flashCallback", flashCallback);

			} catch(e:*) {}
			VK = new APIConnection(flashVars, this);

			createListeners();// тепреь можно повесить листенеры

			if(flashVars.referrer == "wall_view_inline"){
				dispatchEvent(new ArrowEvent('wall_view_inline'));
			}else if(flashVars.referrer == "wall_post_inline"){
				dispatchEvent(new ArrowEvent('wall_post_inline'));
			}else{
				connectToApi()
			}
		}

		// слушать события от wrapper и диспатчить предусмотренные события класса SocialAdapter
		protected function createListeners():void {
			// hook из-за обновления vkontakte.ru, передающих hash во flashVars а не как http://app_url#hash
			if(flashVars["post_id"]){
				try{
					location = HashModem.demodulate(flashVars["post_id"]);
				}catch(e:Error){
					location = flashVars["post_id"];
				}
				dispatchEvent(new ArrowEvent(ArrowEvent.LOCATION_CHANGED));
			}

			VK.addEventListener("onLocationChanged", onLocationChanged);
			VK.addEventListener("onBalanceChanged", onBalanceChanged);
			VK.addEventListener("onSettingsChanged", onSettingsChanged);
		}

		private function onBalanceChanged(e:Object):void{
			balance = e.balance * 0.01;
			dispatchEvent(new ArrowEvent(ArrowEvent.BALANCE_CHANGED));
		}

		// листенер на событие wrapper
		private function onSettingsChanged(e:Object):void{
			flashVars["api_settings"] = e.settings;
			permissions = fromVkPermissions(flashVars["api_settings"]);
			dispatchEvent(new ArrowEvent(ArrowEvent.PERMISSION_CHANGED));
		}

		private function onLocationChanged(e:Object):void
		{
			if(e["location"] && e["location"].length > 0 && (location == null || flashVars["post_id"] == null))
			{
				location = e["location"];
				try{
					location =  HashModem.demodulate(e.location);
				}catch(e:Error){
				}
				dispatchEvent(new ArrowEvent(ArrowEvent.LOCATION_CHANGED));
			}
		}

		override public function showInviteWindow():void {
			VK.callMethod("showInviteBox");
		}

		private var paymentCallSession:uint;
		override public function pay(quantity:Object, onSuccess:Function, onFailure:Function, params:Object = null):void {
			var socialMoney:Number = int(quantity);
			if(balanceLoading)
				return;
			else{
				balanceLoading = true;
				call("getUserBalance", null, function(response:ArrowEvent):void{
					balanceLoading = false;
					if(Number(response.response.response) * 0.01 != balance)
						onBalanceChanged({"balance": Number(response.response.response)});
					if(balance < socialMoney){
						var session:uint = paymentCallSession = getTimer();
						addEventListener(ArrowEvent.BALANCE_CHANGED, function(e:ArrowEvent):void{
							removeEventListener(response.type, arguments.callee);
							if(paymentCallSession == session && balance >= socialMoney)
								onSuccess();
						});
						VK.callMethod("showPaymentBox",(socialMoney - balance));
					}else{
						onSuccess();
					}
				}, function(error:ArrowEvent):void{
					balanceLoading = false;
					onFailure();
				});
			}
		}

		override public function posting(user:SocialUser = null, title:String = null, message:String = null, image:* = null, imageUrl:String = null, data:String = null, onComplete:Function = null, onError:Function = null, additionParams:Object = null):void {
			if(!user)
				user = getUser();
			VK.callMethod("showRequestBox", user.id, message, data);
		}

		override public function setPermissions(required:uint = 0):void {
			if(!required)
				required = ArrowPermission.DEFAULT
			VK.callMethod("showSettingsBox", toVkPermissions(required));

		}

		override public function installApp(requredPermissions:uint = 0):void {
			VK.callMethod("showInstallBox");
			VK.addEventListener("onApplicationAdded", function(e:Object):void{
				VK.removeEventListener("onAplicationAdded", arguments.callee);
				flashVars["is_app_user"] = 1;
				dispatchEvent(new ArrowEvent(ArrowEvent.APP_INSTALLED));
			});
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
			permissions = fromVkPermissions(flashVars["api_settings"]);
			refresh();// сразу запускаем инициализацию
		}

		private function fromVkPermissions(perm:uint):uint {
			var fromVk:uint = 0;
			if(perm & 1) fromVk |= ArrowPermission.NOTIFY;
			if(perm & 2) fromVk |= ArrowPermission.FRIENDS_PROFILES;
			return fromVk | DEFAULT_PERMISSIONS;
		}

		private function toVkPermissions(perm:uint):uint {
			var toVk:uint = 0;
			if(perm & ArrowPermission.NOTIFY) toVk |= 1;
			if(perm & ArrowPermission.FRIENDS_PROFILES) toVk |= 2;
			return toVk;
		}

		protected function execute(code:String, onComplete:Function, onError:Function = null):void{
			call("execute", {"code": code}, onComplete, onError);
		}

		override protected function startInitLoading():void{
			var forExecution:Array = [];
			if(flashVars["api_result"] != null && flashVars["api_result"] != "" )
				initData = jsonDecode(flashVars["api_result"]).response;

			if(initData.user==null){
				forExecution.push('"user":API.getProfiles({"uids":' + flashVars["viewer_id"] + ',"fields":"uid,first_name,last_name,nickname,sex,bdate,photo,photo_medium,photo_big,has_mobile,rate"})');
			}else{
				initData.user = initData.user[0];
				if(initData.city && initData.city[0])
				{
					initData.user.city = initData.city[0].name;
					initData.user.cityCode = initData.city[0].cid;
				}
				if(initData.country && initData.country[0])
				{
					initData.user.country = initData.country[0].name;
					initData.user.countryCode = initData.country[0].cid;
				}
			}

			if(initData.balance==null)
				forExecution.push('"balance":API.getUserBalance()');

			if(initData.friends==null)
				forExecution.push('"friends":API.getProfiles({"uids":API.getFriends(),"fields":"uid,first_name,last_name,photo,photo_medium,sex"})');

			if(initData.appFriends==null)
				forExecution.push('"appFriends":API.getAppFriends()');

			if(initData.groups==null)
				forExecution.push('"groups":API.getGroups()');

			if(forExecution.length)
				execute('return{' + forExecution.join() + '};'	,function(response:ArrowEvent):void{
					var data:Object = response.response.hasOwnProperty('response') ? response.response.response : response.response;
					// complete
					if(data.user!=null)
						initData.user = data.user[0];
					if(data.friends!=null)
						initData.friends = data.friends as Array || [];
					if(data.appFriends!=null)
						initData.appFriends = data.appFriends as Array || [];
					if(data.balance!=null)
						balance = data.balance * 0.01;
					if(data.groups!=null) {
						initData.groups = data.groups as Array || [];
					}
					checkInitLoadingCompletion();
				}, function(response:ArrowEvent):void{
					// error
					if(initParams['error'])
						initParams['error']();
				});
			else
				checkInitLoadingCompletion();
		}

		/**
		 * Действительно обратиться к соц сети за профайлами
		 */
		override protected function getUserProfiles(uids:Array, onComplete:Function, onError:Function):void
		{
			if(uids.length)
				call("getProfiles", {"uids": uids.join(), "fields": "sex,photo,photo_medium,city,country,bdate"}, ckeckArray, onError);
			else
			{
				var event:ArrowEvent = new ArrowEvent(ArrowEvent.REQUEST_SUCCESS);
				event.response = [];
				onComplete && onComplete(event);
			}

			function ckeckArray(obj:ArrowEvent):void
			{

				var array:Array = obj.response.response || [];
				for (var i:int = 0; i < array.length; i++) {
					array[i] = array[i] is SocialUser ? array[i] : createSocialUser(array[i]);
				}
				obj.response = array;
				onComplete && onComplete(obj);
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
			socialUser.nickName = info["nickname"];
			socialUser.homepage = 'http://vk.com/id' + socialUser.id;
			socialUser.male = info["sex"]!=1;
			socialUser.city = info['city']?info['city']:'';
			socialUser.country = info['country']?info['country']:'';
			if(info['cityCode']) socialUser.cityCode = info['cityCode'];
			if(info['countryCode']) socialUser.countryCode = info['countryCode'];
			if( info["photo"] && info["photo"].toString().lastIndexOf("http://vkontakte.ru/images/") != -1 ) info["photo"]=null;
			if( info["photo_medium"] && info["photo_medium"].toString().lastIndexOf("http://vkontakte.ru/images/") != -1 ) info["photo_medium"]=null;
			if( info["photo_big"] && info["photo_big"].toString().lastIndexOf("http://vkontakte.ru/images/") != -1 ) info["photo_big"]=null;
			if( !info["photo_medium"] ) info["photo_medium"] = info["photo"];
			if( !info["photo_big"] ) info["photo_big"] = info["photo_medium"];
			socialUser.photos = [info["photo"],info["photo_medium"],info["photo_big"]];
			if(info["bdate"]){
				var a:Array = info["bdate"].split(".");
				var d:Date = new Date(Number(a[2] == null?new Date().fullYear:a[2]), Number(a[1]) - 1, Number(a[0]));
				socialUser.birthday = d;
			}
			return socialUser;
		}

		override protected function getUrlVariables(method:String, params:Object, flags:Object):URLVariables
		{
			var urlVariables:URLVariables = super.getUrlVariables(method, params, flags);
			urlVariables["method"] = method;
			urlVariables["api_id"] = flashVars["api_id"];
			urlVariables["format"] = "JSON";
			urlVariables["v"] = "3.0";
			return urlVariables;
		}

		override protected function getApiPath(method:String, params:Object, flags:Object):String
		{
			return flashVars["api_url"] ? flashVars["api_url"] : "http://api.vkontakte.ru/api.php";
		}

		override protected function appInstalled():Boolean{
			return flashVars["is_app_user"] == 1;
		}

		/**
		 * Создать подпись запроса (если в этом есть необходимость для текущей соц. сети)
		 */
		override protected function postprocessParams(urlVariables:URLVariables):void{
			var signature:String = "";
			var sorted_array: Array = [];
			for (var key:String in urlVariables) {
				sorted_array.push(key + "=" + urlVariables[key]);
			}
			sorted_array.sort();
			for (key in sorted_array) {
				signature += sorted_array[key];
			}
			urlVariables["sig"] = MD5.hash(flashVars["viewer_id"] + signature + flashVars['secret']);
			urlVariables["sid"] = flashVars["sid"];
		}

		/**
		 * Функция должна быть переопределена
		 * С сервера пришел ответ. Необходимо его обработать по специфике, принятой в данной соц. сети
		 * (например перевести данные в объект через JSON)
		 * Также необходимо провести обработку ошибок
		 * @param response ответ от сервера
		 * @param onComplete
		 * @param onError
		 * @return ответ от сервера не содержит ошибок
		 */
		override protected function responseHandler(response:String, method:String, params:Object = null, onComplete:Function = null, onError:Function = null, flags:Object = null):Object{
			var responseObject:Object = super.responseHandler(response, method, params, onComplete, onError, flags);
			if(responseObject)
			{
				if(responseObject.hasOwnProperty('error'))
				{
					// TODO: обработка типа ошибки
					fireApiRequestEvent(onError, method, params, flags, responseObject, ArrowError.RESPONSE_ERROR);
				}
				else
				{
					fireApiRequestEvent(onComplete, method, params, flags, responseObject)
				}
			}
			return responseObject;
		}

		/**
		 * Обеспечивает работу с callback-s из js так, будто они происходят непосредственно из флешки
		 */
		public var flashCallbacks:Dictionary = new Dictionary(true);
		public var flashCallbacksCounter:uint = 0;
		public function flashCallback(name:String, args:Array):void{
			if(args.length > 0)
				if(name == "api"){
					if(flashCallbacks[args[0]])
						CallbackPair(flashCallbacks[args[0]]).call(args[1], args[2]);
					delete flashCallbacks[args[0]];
				}
		}
	}
}


import com.somewater.arrow.ArrowVkcom;
import com.somewater.arrow.IArrow;

import flash.events.*;
import flash.external.ExternalInterface;
import flash.net.LocalConnection;
import flash.utils.setTimeout;



dynamic class CustomEvent extends Event {
	public static const CONN_INIT: String = "onConnectionInit";
	public static const WINDOW_BLUR: String = "onWindowBlur";
	public static const WINDOW_FOCUS: String = "onWindowFocus";
	public static const APP_ADDED: String = "onApplicationAdded";
	public static const WALL_SAVE: String = "onWallPostSave";
	public static const WALL_CANCEL: String = "onWallPostCancel";
	public static const PHOTO_SAVE: String = "onProfilePhotoSave";
	public static const PHOTO_CANCEL: String = "onProfilePhotoCancel";



	public function CustomEvent(params:Object, type : String, bubbles : Boolean = false, cancelable : Boolean = false) {
		super(type, bubbles, cancelable);

		if(params)
			for(var s:String in params)
				this[s] = params[s];
	}

	override public function clone():Event
	{
		var d:CustomEvent = new CustomEvent(null, type, bubbles, cancelable);

		for(var s:String in this)
			d[s] = this[s];

		return d;
	}
}




class APIConnection extends EventDispatcher {
	private var sendingLC: LocalConnection;
	private var connectionName: String;
	private var receivingLC: LocalConnection;

	private var pendingRequests: Array;
	private var loaded: Boolean = false;

	private var dp:ArrowVkcom;


	public function APIConnection(params:Object, socialAdapter:ArrowVkcom) {
		var connectionName: String;
		if (typeof(params) == 'string') {
			connectionName = String(params);
		} else {
			connectionName = params.lc_name;
			var api_url: String = 'http://api.vkontakte.ru/api.php';
			if (params.api_url) api_url = params.api_url;
			//dp = new DataProvider(api_url, params[0].api_id, params[0].sid, params[0].secret, params[0].viewer_id);
		}
		dp = socialAdapter;
		if (!connectionName) {trace('[ERROR] connection "lc_name" undefined');return;}
		connectionName = connectionName;
		trace("connectionName=" + connectionName);
		pendingRequests = new Array();

		this.connectionName = connectionName;

		sendingLC = new LocalConnection();
		sendingLC.allowDomain('*');

		receivingLC = new LocalConnection();
		receivingLC.allowDomain('*');
		receivingLC.client = {
			initConnection: initConnection,
			onBalanceChanged: onBalanceChanged,
			onSettingsChanged: onSettingsChanged,
			onLocationChanged: onLocationChanged,
			onWindowResized: onWindowResized,
			onApplicationAdded: onApplicationAdded,
			onWindowBlur: onWindowBlur,
			onWindowFocus: onWindowFocus,
			onWallPostSave: onWallPostSave,
			onWallPostCancel: onWallPostCancel,
			onProfilePhotoSave: onProfilePhotoSave,
			onProfilePhotoCancel: onProfilePhotoCancel,
			onMerchantPaymentSuccess: onMerchantPaymentSuccess,
			onMerchantPaymentCancel: onMerchantPaymentCancel,
			onMerchantPaymentFail: onMerchantPaymentFail,
			customEvent: _customEvent
		};
		try {
			receivingLC.connect("_out_" + connectionName);
		} catch (error:ArgumentError) {
			debug("Can't connect from App. The connection name is already being used by another SWF");
		}
		receivingLC.addEventListener(StatusEvent.STATUS, onStatus);
		sendingLC.addEventListener(StatusEvent.STATUS, onStatus);
		sendingLC.addEventListener(StatusEvent.STATUS, onInitStatus);
		sendingLC.send("_in_" + connectionName, "initConnection");
	}


	private function onStatus(e:StatusEvent):void
	{
		trace(e.currentTarget + ":	level=" + e.level + "	code=" + e.code)
	}

	/*
	* Public methods
	*/
	public function callMethod(...params):void {
		var paramsArr: Array = params as Array;
		paramsArr.unshift("callMethod");
		sendData.apply(this, paramsArr);
	}

	public function debug(msg: *): void {
		if (!msg || !msg.toString) {
			return;
		}
		sendData("debug", msg.toString());
	}

	public function api(method: String, params: Object, onComplete:Function = null, onError:Function = null):void {
		//dp.request(method, params, onComplete, onError);
		if(ExternalInterface.available)
		{
			var arr:Array = [];
			for(var s:String in params){
				arr.push(s);
				arr.push(params[s]);
			}
			dp.flashCallbacksCounter++;
			arr.unshift(dp.flashCallbacksCounter);
			arr.unshift(method);
			arr.unshift("call_API");// название принимающей функции JS
			for(var i:int = 0;i<arr.length;i++)
				trace(i + ")" + arr[i]);

			dp.flashCallbacks[dp.flashCallbacksCounter] = new CallbackPair(onComplete, onError);

			ExternalInterface.call.apply(null, arr);
		}else
		{
			throw new Error("External interface not available");
		}
	}

	public function navigateToURL(url: String, window: String = "_self"): void {
		this.callMethod("navigateToURL", url, window);
	}

	/*
	* Callbacks
	*/
	private function initConnection(): void {
		if (loaded) return;
		loaded = true;
		debug("Connection initialized.");
		dispatchEvent(new CustomEvent(null, CustomEvent.CONN_INIT));
		sendPendingRequests();
	}

	public function _customEvent(...params): void {
		var paramsArr: Array = params as Array;
		var eventName: String = paramsArr.shift();
		debug(eventName);
		var e:CustomEvent = new CustomEvent(null, eventName);
		e.params = paramsArr;
		dispatchEvent(e);
	}

	/*
	* Obsolete callbacks
	*/
	private function onBalanceChanged(...params): void {
		var paramsArr: Array = params as Array;
		//paramsArr.unshift('onBalanceChanged')
		//customEvent.apply(this, paramsArr);
		dispatchEvent(new CustomEvent({"balance":params[0]}, 'onBalanceChanged'));
	}

	private function onSettingsChanged(...params): void {
		//var paramsArr: Array = params as Array;
		//paramsArr.unshift('onSettingsChanged')
		//customEvent.apply(this, paramsArr);
		dispatchEvent(new CustomEvent({"settings":params[0]}, 'onSettingsChanged'));
	}

	private function onLocationChanged(...params): void {
		//var paramsArr: Array = params as Array;
		//paramsArr.unshift('onLocationChanged')
		//customEvent.apply(this, paramsArr);
		dispatchEvent(new CustomEvent({"location":params[0]}, 'onLocationChanged'));
	}

	private function onWindowResized(...params): void {
		//var paramsArr: Array = params as Array;
		//paramsArr.unshift('onWindowResized')
		//customEvent.apply(this, paramsArr);
		dispatchEvent(new CustomEvent({"width":params[0], "height":params[1]}, 'onWindowResized'));
	}

	private function onApplicationAdded(...params): void {
		//var paramsArr: Array = params as Array;
		//paramsArr.unshift('onApplicationAdded')
		//customEvent.apply(this, paramsArr);
		dispatchEvent(new CustomEvent(null, 'onApplicationAdded'));
	}

	private function onWindowBlur(...params): void {
		//var paramsArr: Array = params as Array;
		//paramsArr.unshift('onWindowBlur')
		//customEvent.apply(this, paramsArr);
		dispatchEvent(new CustomEvent(null, 'onWindowBlur'));
	}

	private function onWindowFocus(...params): void {
		//var paramsArr: Array = params as Array;
		//paramsArr.unshift('onWindowFocus')
		//customEvent.apply(this, paramsArr);
		dispatchEvent(new CustomEvent(null, 'onWindowFocus'));
	}

	private function onWallPostSave(...params): void {
		//var paramsArr: Array = params as Array;
		//paramsArr.unshift('onWallPostSave')
		//customEvent.apply(this, paramsArr);
		dispatchEvent(new CustomEvent(null, 'onWallPostSave'));
	}

	private function onWallPostCancel(...params): void {
		//var paramsArr: Array = params as Array;
		//paramsArr.unshift('onWallPostCancel')
		//customEvent.apply(this, paramsArr);
		dispatchEvent(new CustomEvent(null, 'onWallPostCancel'));
	}

	private function onProfilePhotoSave(...params): void {
		//var paramsArr: Array = params as Array;
		//paramsArr.unshift('onProfilePhotoSave')
		//customEvent.apply(this, paramsArr);
		dispatchEvent(new CustomEvent(null, 'onProfilePhotoSave'));
	}

	private function onProfilePhotoCancel(...params): void {
		//var paramsArr: Array = params as Array;
		//paramsArr.unshift('onProfilePhotoCancel')
		//customEvent.apply(this, paramsArr);
		dispatchEvent(new CustomEvent(null, 'onProfilePhotoCancel'));
	}

	private function onMerchantPaymentSuccess(...params): void {
		//var paramsArr: Array = params as Array;
		//paramsArr.unshift('onMerchantPaymentSuccess')
		//customEvent.apply(this, paramsArr);
		dispatchEvent(new CustomEvent({"merchantOrderId":params[0]}, 'onMerchantPaymentSuccess'));
	}

	private function onMerchantPaymentCancel(...params): void {
		//var paramsArr: Array = params as Array;
		//paramsArr.unshift('onMerchantPaymentCancel')
		//customEvent.apply(this, paramsArr);
		dispatchEvent(new CustomEvent(null, 'onMerchantPaymentCancel'));
	}

	private function onMerchantPaymentFail(...params): void {
		//var paramsArr: Array = params as Array;
		//paramsArr.unshift('onMerchantPaymentFail')
		//customEvent.apply(this, paramsArr);
		dispatchEvent(new CustomEvent(null, 'onMerchantPaymentFail'));
	}

	/*
	* Private methods
	*/
	private function sendPendingRequests(): void {
		while (pendingRequests.length) {
			sendData.apply(this, pendingRequests.shift());
		}
	}

	private function sendData(...params):void {
		var paramsArr: Array = params as Array;
		if (loaded) {
			paramsArr.unshift("_in_" + connectionName);
			sendingLC.send.apply(null, paramsArr);
		} else {
			pendingRequests.push(paramsArr);
		}
	}
	private function onInitStatus(e:StatusEvent):void {
		if(e.level == "error")
		{
			receivingLC.close();
			try
			{
				receivingLC.connect("_out_" + connectionName);
			}catch(e:Error){trace("LocalConnection reconnect error"); return;}
			sendingLC.send("_in_" + connectionName, "initConnection");
			return;
		}
		trace("LocalConnection success");
		debug("StatusEvent: "+e.level);
		e.target.removeEventListener(e.type, onInitStatus);
		if (e.level == "status") {
			receivingLC.client.initConnection();
		}
	}
}

class CallbackPair{

	public var onComplete:Function;
	public var onError:Function;

	public function CallbackPair(onComplete:Function, onError:Function){
		this.onComplete = onComplete;
		this.onError = onError;
	}

	public function call(success:Boolean, data:Object):void
	{
		success && onComplete && onComplete(data);
		!success && onError && onError(data);
		clear();
	}

	public function clear():void{
		onComplete = null;
		onError = null;
	}
}
