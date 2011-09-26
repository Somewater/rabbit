package com.somewater.social
{
	import com.adobe.images.JPGEncoder;
	import com.progrestar.common.util.JSON;
	import com.progrestar.common.util.HashModem;
	
	import flash.events.Event;
	import flash.external.ExternalInterface;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.net.URLRequestHeader;
	import flash.utils.ByteArray;
	import flash.utils.Dictionary;

	/**
	 * Работа с вконтакте, используя LocalConnection и JS API
	 */
	public class VkontakteLCSocialAdapter extends VkontakteSocialAdapter
	{
		private var VK:APIConnection;
		
		
		public function VkontakteLCSocialAdapter()
		{
			super();
			
			PERMISSION_WALL_USER_MASK = 1;// TODO
		}
		
		override protected function preRefresh():void
		{
			super.preRefresh();
			try {
				if(ExternalInterface.available)
					ExternalInterface.addCallback("flashCallback", flashCallback);
				
			} catch(e:*) {}
			VK = new APIConnection(flashVars, this);
			
			wrapper = VK;
			
			flashVars["post_id"] = null;// затираем, т.к. если параметр был задан, его обработка уже была осуществлена ранее
			createListeners();// тепреь можно повесить листенеры
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
				}else if(name == "geolocation"){
					var response:Object = args[1]?{"success":true, "lat":args[2], "lng":args[3], "acc":args[4], "utime":args[5]}
													:{"success":false, "error":{"code":args[2], "message":args[3]}};
					if(flashCallbacks[args[0]])
						CallbackPair(flashCallbacks[args[0]]).call(args[1],response);
					dispatchEvent(new CustomEvent(response, "geolocation"));
				}
		}

		
		/**
		 * Получить геолокацию через JS
		 * @param onComlete функция на получение результата вида function({success:true, lat, lng, acc, utime})
		 * @param onError функция на ошибку при получении результата, либо на отмену пользователем вида function({success:false,error:{code,message}})
		 * 
		 */
		public function getGeolocation(onComplete:Function, onError:Function = null):void
		{
			if(ExternalInterface.available)
			{
				flashCallbacksCounter++;
				flashCallbacks[flashCallbacksCounter] = new CallbackPair(onComplete, onError);
				ExternalInterface.call("getGeolocation", flashCallbacksCounter);
			}
		}
		
		
		
		// раскомментить для JS API
		/*override protected function _sendRequest(method:String, request:Object=null, onComplete:Function=null, onError:Function=null, GET:Boolean=false):void
		{
			VK.api(method, request, onComplete, onError);
		}*/

		
		override public function showInstallBox(settings:*=null):Boolean{
			VK.callMethod("showInstallBox");
			wrapper.addEventListener("onApplicationAdded", function(e:Object):void{
				wrapper.removeEventListener("onAplicationAdded", arguments.callee);
				flashVars["is_app_user"] = 1;
				dispatchEvent(new Event(SocialAdapter.EVENT_INSTALL_APP_COMPLETE));
			});
			return true;
		}
		
		override public function showSettingsBox(settings:*=null):Boolean{
			VK.callMethod("showSettingsBox", (int(settings) == 0? MANDATORY_PERMISSION_MASK: settings));
			wrapper.removeEventListener("onSettingsChanged", onSettingsChanged);// удаляем, на случай, если листенер уже был присвоен (например пользоваетль закрыл окно настроек в первый раз)
			wrapper.addEventListener("onSettingsChanged", onSettingsChanged);
			return true;
		}
		
		override public function showInviteBox(uid:String = null, type:String = null, onComplete:Function = null, onError:Function = null):Boolean{
			VK.callMethod("showInviteBox");
			return true;
		}

		
		override public function showPaymentBox(socialMoney:Number, onSuccess:Function=null, title:String=null, message:String=null, code:String=null, params:Object=null):Boolean
		{
			if(balanceLoading)
				return false;
			else{
				balanceLoading = true;
				loadUserBalance(function(result:Object):void{
					balanceLoading = false;
					if(Number(result) * 0.01 != balance)
						onBalanceChanged({"balance": result});
					if(balance < socialMoney){
						addEventListener("onBalanceChanged", function(e:Event):void{
							removeEventListener("onBalanceChanged", arguments.callee);
							if(balance >= socialMoney)
								onSuccess();
						});
						VK.callMethod("showPaymentBox",(socialMoney - balance));
					}else{
						onSuccess();
					}
				}, function(error:Object):void{
					balanceLoading = false;
				});	
				return true;
			}
		}
		
		override public function resizeApplication(width:int, height:int):Boolean {
			if(CAN_RESIZE) {
				VK.callMethod("resizeWindow",width, height);
				return true;
			} 
			return false;
		}
		
		// раскомментить для JS API
		/*override protected function wallPostManager_savePhoto(upload_url:String):void{
			var jpgEncode:ByteArray= new JPGEncoder(90).encode(wallPostManager_image);
			var header:URLRequestHeader=new flash.net.URLRequestHeader("Content-type", "multipart/form-data; boundary=abc");
			var byteArray:ByteArray=new flash.utils.ByteArray();
			byteArray.writeUTFBytes("--abc\r\nContent-Disposition: form-data; name=\""+(wallPostManager_album == null?"photo":"file1")+"\"; filename=\"post.jpg\"\r\nContent-Type: image/jpeg\r\n\r\n");
			byteArray.writeBytes(jpgEncode);
			byteArray.writeUTFBytes("\r\n--abc--\r\n");
			var request:URLRequest=new flash.net.URLRequest();
			request.requestHeaders.push(header);
			request.url = upload_url;
			request.method = flash.net.URLRequestMethod.POST;
			request.data = byteArray;
			
			//var mess:String = byteArrayToString(jpgEncode);
			//trace(mess);
			
			var saver:URLLoader = new flash.net.URLLoader();
			saver.addEventListener(Event.COMPLETE, wallPostManager_onSavePhotoComplete);
			saver.load(request);

			
			//ExternalInterface.call("wallPost", upload_url, mess);
			
			function byteArrayToString(ba:ByteArray):String 
			{
				var acum:String = "";
				
				ba.position = 0;
				
				while (ba.position < ba.length) {
					var dat:String = ba.readUnsignedByte().toString(16);
					
					while (dat.length < 2) dat = "0" + dat;
					
					acum += dat;
				}
				
				ba.position = 0;
				
				return acum;
			}

		}*/
		
		
		override protected function wallPostManager_onSavePostComplete(e:Object):void{			
			wrapper.addEventListener("onWallPostSave", wallPostManager_onWallPostSave);
			wrapper.addEventListener("onWallPostCancel", wallPostManager_onWallPostCancel);
			VK.callMethod("saveWallPost",e.post_hash);
		}
		
		
		
		
	}
	
}

import com.somewater.social.SocialAdapter;
import com.somewater.social.VkontakteLCSocialAdapter;

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
	
	private var dp:VkontakteLCSocialAdapter;
	
	
	public function APIConnection(params:Object, socialAdapter:VkontakteLCSocialAdapter) {
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
		if (!connectionName) return;
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