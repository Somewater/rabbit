package com.somewater.social
{
	import com.adobe.crypto.MD5;
	import com.adobe.images.JPGEncoder;
	import com.adobe.serialization.json.JSON;
	
	import com.somewater.storage.HashModem;
	
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.events.Event;
	import flash.events.TimerEvent;
	import flash.geom.Matrix;
	import flash.geom.Rectangle;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.net.URLRequestHeader;
	import flash.net.URLVariables;
	import flash.utils.ByteArray;
	import flash.utils.Timer;
	import flash.utils.getQualifiedClassName;
	import flash.utils.getQualifiedSuperclassName;
	import flash.utils.getTimer;
	
	
	public class VkontakteSocialAdapter extends SocialAdapter
		
	{
		
		public var wrapper:Object;
		protected var balance:Number = 0;

        /**
         * Приписывать к запросам флаг test_mode, т.к. иначе флешка выдает ошибку
         */
        protected var useTestMode:Boolean = false;
		
		/**
		 * Дополнительные callback-функции для обработки открытия приложения со стены:
		 * onWallViewInline когда приложение открыто со стены. В функцию передается объект flashVars: onWallViewInline(flashVars:Object)
		 * onWallPost когда приложение открыто ДЛЯ публикации на стену (в режиме "рисовалок на стену", которыми мы, как правило, не занимаемся)
		 * 				в функцию передается объект flashVars: onWallPost(flashVars:Object)
		 * hash постинга содержится в параметре flashVars.post_id
		 * id отправителя содержится в парамтере flashVars.poster_id
		 */
		public var onWallPostInline:Function;
		public var onWallViewInline:Function;
		
		public function VkontakteSocialAdapter()
		{
			CAN_RESIZE = true;
			
			PERMISSION_BOOKMARK_MASK = 256;
			PERMISSION_NOTIFICATION_MASK = 1;
			PERMISSION_FRIENDS_MASK = 2;
			PERMISSION_PHOTO_MASK = 4;
			PERMISSION_STATUS_MASK = 1024;
			PERMISSION_NOTES_MASK = 2048;
			PERMISSION_WALL_USER_MASK = 0;// т.е. отказываемся от возможности постить на стену юзера, потому что там это все равно никто кроме него не увидит 
			PERMISSION_WALL_FRIEND_MASK = PERMISSION_WALL_APPFRIEND_MASK = 1;// т.е. вегда работает,т.к. входит в обязательные настройки
			PERMISSION_WALL_GET_MASK = 8192;
			
			super();
		}

		override public function get PERMISSION_WALL_USER():Boolean
		{
			return true;// себе можно постить всегда
		}

		
		override public function setBookmarkCounter(value:int=0, onSuccess:Function=null, onError:Function=null):void {
			if(PERMISSION_BOOKMARK) {
				_sendRequest('setCounter', {counter:value}, onSuccess, onError);
			} else {
				onError && onError();
			}
		}
		
		override public function get networkUrlAddress():String
		{
			return flashVars["domain"]?("http://" +  flashVars["domain"]):"http://vkontakte.ru";
		}
		
		
		override public function get app_id():String
		{
			return flashVars["api_id"];
		}
		
		
		override public function init(flashVarsHolder:Object, onComplete:Function, onError:Function = null, secret_keys:* = null):void{
			if(flashVarsHolder is DisplayObject){
				if(getQualifiedSuperclassName(flashVarsHolder) == "mx.core::Application"){
					if(flashVarsHolder.parent.parent.parent){
						wrapper = flashVarsHolder.parent.parent.parent;
						flashVarsHolder = wrapper.application.parameters;
					}
				}else if(flashVarsHolder.parent && flashVarsHolder.parent.parent){
					wrapper = flashVarsHolder.parent.parent;
					flashVarsHolder = wrapper.application.parameters;
				}				
			}
			
			// весь super.init кроме запуска refresh()
			onInitComplete = onComplete;
			onInitError = onError;
			keys = secret_keys;
			if(wrapper == null && flashVarsHolder["loaderInfo"] && (flashVarsHolder is DisplayObject))
				if(flashVarsHolder["loaderInfo"]["parameters"])
					flashVarsHolder = flashVarsHolder["loaderInfo"]["parameters"];					
			this.flashVars = flashVarsHolder;
			
			if(flashVars.referrer == "wall_view_inline"){
				if(onWallViewInline != null){
					initState = 4;
					onWallViewInline(flashVars);
				}else
					throw new Error("\"Wall View\" handler not specified");
			}else if(flashVars.referrer == "wall_post_inline"){
				if(onWallPostInline != null){
					initState = 4;
					onWallPostInline(flashVars);
				}else
					throw new Error("\"Wall Post\" handler not specified");
			}else{
				createListeners();
				preRefresh();
				if(autoRefresh)
					refresh();// можно запускать refresh если никак не связано со стеной
			}
		}
		
		override public function wallGet(onComplete:Function = null, onError:Function = null) : void {
			if(PERMISSION_WALL_GET) {
				_sendRequest('wall.get',{filter:'all',offset:0,count:50},onComplete, onError);
			} else {
				removeEventListener(SocialAdapter.EVENT_PERMISSION_CHANGED, onWallGetSettingChange);
				addEventListener(SocialAdapter.EVENT_PERMISSION_CHANGED, onWallGetSettingChange);
				lastWallGetArgs = arguments;
				showSettingsBox(PERMISSION_WALL_GET_MASK);
			}
		}
		private var lastWallGetArgs : Array;
		private function onWallGetSettingChange(...params) : void {
			removeEventListener(SocialAdapter.EVENT_PERMISSION_CHANGED, onWallGetSettingChange);			
			if(lastWallGetArgs) {
				wallGet.apply(this,lastWallGetArgs);
				lastWallGetArgs = null;
			}
		}
		
		// слушать события от wrapper и диспатчить предусмотренные события класса SocialAdapter
		protected function createListeners():void{
			wrapper && wrapper.addEventListener("onLocationChanged", function(e:Object):void{
				if(e["location"] && e["location"].length > 0 && (location == null || flashVars["post_id"] == null))
				{
					location = e["location"];
					try{
						location =  HashModem.demodulate(e.location);
					}catch(e:Error){
					}
					dispatchEvent(new Event(SocialAdapter.EVENT_LOCATION_CHANGED));
				}
			});
			// hook из-за обновления vkontakte.ru, передающих hash во flashVars а не как http://app_url#hash
			if(flashVars["post_id"]){
				try{
					location = HashModem.demodulate(flashVars["post_id"]);
				}catch(e:Error){
					location = flashVars["post_id"];
				}
				dispatchEvent(new Event(SocialAdapter.EVENT_LOCATION_CHANGED));
			}
			
			wrapper && wrapper.addEventListener("onBalanceChanged", onBalanceChanged);
		}
		
		override protected function preRefresh():void{
			PERMISSIONS = flashVars["api_settings"];
		}
		
		protected function execute(code:String, onComplete:Function, onError:Function = null):void{
			_sendRequest("execute", {"code": code}, onComplete, onError);
		}
		
		override public function createSocialUser(info:Object):SocialUser{
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
		
		override public function get authentication_key():String{
			if(flashVars)
				return flashVars["auth_key"];
			else
				throw new Error("SocialAdapter don`t initialized");
		}
		
		/**
		 * Установить счетчик рядом с приложением (если приложение было добавлено в левое меню)
		 */
		public function setCounter(value:int, onComplete:Function = null, onError:Function = null):void
		{
			_sendRequest("setCounter", {"timestamp":int(new Date().time * 0.01).toString(), "random":int(Math.random() * 10000), "counter":value}, onComplete, onError);
		}
		
		override public function loadProfiles(uids:Array, onComplete:Function, onError:Function=null):void{
			if(uids.length)
				_sendRequest("getProfiles", {"uids": uids.join(), "fields": "sex,photo,photo_medium,city,country,bdate"}, ckeckArray, onError);
			else
				onComplete && onComplete([]);
			
			function ckeckArray(obj:Object):void
			{
				if(obj is Array)
					onComplete && onComplete(obj);
				else
					onComplete && onComplete([]);
			}
		}
		
		override public function loadUserProfile(onComplete:Function, onError:Function=null):void{
			_sendRequest("getProfiles", {"uids": flashVars["viewer_id"], "fields": "sex,photo,photo_medium,photo_big,city,country,bdate"}, innerOnComplete, onError);
			function innerOnComplete(e:Object):void{
				onComplete(e[0]);
			}
		}
		
		override public function loadUserFriends(onComplete:Function, onError:Function=null):void{
			_sendRequest("friends.get", null, onComplete, onError);
		}
		
		override public function loadUserGroups(onComplete:Function, onError:Function=null):void {
			_sendRequest("getGroups", null, onComplete, onError);
		}
		
		
		override public function loadUserFriendsProfiles(onComplete:Function, onError:Function=null):void{
			_sendRequest("friends.get", {"fields": "sex,photo,photo_medium"}, onComplete, onError);
		}
		
		override public function loadUserAppFriends(onComplete:Function, onError:Function=null):void{
			_sendRequest("friends.getAppUsers", null, onComplete, onError);
		}
		
		override public function loadUserBalance(onComplete:Function, onError:Function=null):Boolean{
			_sendRequest("getUserBalance", null, onComplete, onError);
			return true;
		}
		
		override public function showInstallBox(settings:*=null):Boolean{
			if(wrapper){
				wrapper.external.showInstallBox();
				wrapper.addEventListener("onApplicationAdded", function(e:Object):void{
					wrapper.removeEventListener("onAplicationAdded", arguments.callee);
					flashVars["is_app_user"] = 1;
					dispatchEvent(new Event(SocialAdapter.EVENT_INSTALL_APP_COMPLETE));
				});
				return true;
			}
			return false;
		}
		
		override public function showSettingsBox(settings:*=null):Boolean{
			if(wrapper){
				wrapper.external.showSettingsBox(int(settings) == 0? MANDATORY_PERMISSION_MASK: settings);
				wrapper.removeEventListener("onSettingsChanged", onSettingsChanged);// удаляем, на случай, если листенер уже был присвоен (например пользоваетль закрыл окно настроек в первый раз)
				wrapper.addEventListener("onSettingsChanged", onSettingsChanged);
				return true;
			}
			return false;
		}
		
		override public function showInviteBox():Boolean{
			wrapper && wrapper.external.showInviteBox();
			return wrapper != null;
		}
		
		protected var balanceLoading:Boolean = false;// происходит перезагрузка баланса (нельзя вызывать окно, так как пока что не извесне баланс узера)
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
						wrapper && wrapper.external.showPaymentBox(socialMoney - balance);
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
			if(CAN_RESIZE && wrapper) {
				wrapper && wrapper.external.resizeWindow(width, height);
				return true;
			} 
			return false;
		}
		
		override public function wallPost(recipient:SocialUser=null, title:String=null, message:String=null, 
										  image:*=null, imageUrl:String=null, postData:String=null, 
										  onComplete:Function=null, onError:Function=null, additionParams:Object=null):Boolean{
			const MAX_SIZE:int = 270;
			if(recipient == null)
				recipient = user;
			if(additionParams && additionParams.imagePostfix) {
				delete additionParams.imagePostfix;
			}
			if(super.wallPost(recipient)){
				var imageBmpData:BitmapData;
				if(image is BitmapData)
					imageBmpData = image;
				else if(image is DisplayObject){
					var scale:Number = Math.min(MAX_SIZE/image.width, MAX_SIZE/image.height);
					imageBmpData = new BitmapData(MAX_SIZE, MAX_SIZE, true, 0);
					imageBmpData.draw(image,  new Matrix(scale, 0, 0, scale));
				}else
					imageBmpData = new BitmapData(MAX_SIZE, MAX_SIZE, false, 0xFFEEEE);// рисунок для осуществления тестовой публикации
				
				// функционал взят из ранее statis класса WallPostManager, все его функции приведены к instanse
				wallPostManager_onComplete = onComplete;
				wallPostManager_onError = onError;
				postData = HashModem.modulate(HashModem.checkSymbols(postData));// вырезать неподдерживаемые символы и закодировать
				wallPostManager_save(null, imageBmpData, message, recipient.id, postData);
				return true;
			}		
			return false;
		}
		
		
		
		/**
		 * Опубликовать статус на стену в формате текст + медиа
		 * пример: attachment = "photo123_321"
		 */
		public function  wallPostJS(recipient:SocialUser, onComplete:Function, onError:Function, msg:String = null, attachment:String = null):void
		{
			if(recipient == null) recipient = user;
			
			var obj:Object = {"owner_id":recipient.id};
			if(msg == null && attachment == null) throw new Error("Both parameters is null"); 
			if(msg) obj["message"] = msg;
			if(attachment) obj["attachment"] = attachment;
			if(wrapper)
				wrapper.external.api("wall.post", obj, onComplete, onError);
			else
				onError && onError({});
		}
		
		
		
		
		protected var lastPhotoArgs : Array;
		override public function photoAlbumPost(albumTitle:String=null, albumDescription:String=null, 
												image:* = null, onComplete:Function = null, 
												onError:Function = null, rectangle:Rectangle=null) : Boolean {
			if(super.photoAlbumPost()) {
				var imageBmpData:BitmapData;
				if(image is BitmapData)
					imageBmpData = image;
				else if(image is DisplayObject){
					imageBmpData = new BitmapData(image.width, image.height, true, 0);
					imageBmpData.draw(image, null, null, null, rectangle,true);
				} else {
					imageBmpData = new BitmapData(100, 100, false, 0xFFEEEE);// рисунок для осуществления тестовой публикации
				}
				
				wallPostManager_onComplete = onComplete;
				wallPostManager_onError = onError;
				wallPostManager_save({title:albumTitle, description:albumDescription}, imageBmpData, '', '', '');
				return true;
			} else {
				removeEventListener(SocialAdapter.EVENT_PERMISSION_CHANGED, onPhotoSettingChange);
				addEventListener(SocialAdapter.EVENT_PERMISSION_CHANGED, onPhotoSettingChange);
				lastPhotoArgs = arguments;
				showSettingsBox(PERMISSION_PHOTO_MASK);
			} 
			return false;
		}

		protected var lastWallPhotoPostParams:Array;
		override public function wallPhotoPost(message:String='', photo:BitmapData=null, okCallback:Function=null, failCallback:Function=null, permissionGrantedCallback:Function=null) : Boolean {
			wallPostManager_wallPhoto = true;
			wallPostManager_onComplete = okCallback;
			wallPostManager_onError = failCallback;
			wallPostManager_image = photo;
			wallPostManager_message = message;
			if(super.wallPhotoPost()) {
				permissionGrantedCallback && permissionGrantedCallback();
				_sendRequest('photos.getWallUploadServer', {}, function(data:Object=null):void{
					wallPostManager_savePhoto(data["upload_url"]);
				},function(data:Object=null):void{
					failCallback && failCallback(data);
				});
				return true;
			} else {				
				removeEventListener(SocialAdapter.EVENT_PERMISSION_CHANGED, onWallPhotoSettingChange);
				addEventListener(SocialAdapter.EVENT_PERMISSION_CHANGED, onWallPhotoSettingChange);
				lastWallPhotoPostParams = arguments;
				showSettingsBox(PERMISSION_PHOTO_MASK);
				return false;
			}
			return false;
		}
		
		private function onWallPhotoSettingChange(e:Event):void {
			wallPhotoPost.apply(this, lastWallPhotoPostParams); 
			removeEventListener(SocialAdapter.EVENT_PERMISSION_CHANGED, onWallPhotoSettingChange);
		}
		
		protected var lastNotepostParams : Array;
		override public function notePost(title: String, text : String=null, okCallback:Function=null, failCallback:Function=null) : void {
			/*
			<div class="wikiText"><a class="wikiPhoto" href="http://vkontakte.ru/photo92619330_200778981" onclick="viewPhoto('photo92619330_200778981', 'http://vkontakte.ru/photo92619330_200778981', '111', true); return false;"><img alt="111" title="111" src="http://cs11008.vkontakte.ru/u92619330/124249833/x_cd0df341.jpg" style="width:500px;height:281px;"/></a> <br/>
			<a class="wikiVkLink" href="http://dig.vkontakte.ru">Копай!</a> <br/>
			пыщ пыщ﻿</div>
			*/
			if(PERMISSION_NOTES) {
				_sendRequest("notes.add", {title:title,text:text}, okCallback, failCallback);
			} else {
				lastNotepostParams = arguments;
				removeEventListener(SocialAdapter.EVENT_PERMISSION_CHANGED, onNoteSettingChange);
				addEventListener(SocialAdapter.EVENT_PERMISSION_CHANGED, onNoteSettingChange);
				showSettingsBox(PERMISSION_NOTES_MASK);
			}
		}
		
		private function onNoteSettingChange(e:Event) : void {
			notePost.apply(this,lastNotepostParams);
			removeEventListener(SocialAdapter.EVENT_PERMISSION_CHANGED, onNoteSettingChange);
		}
		
		private function onPhotoSettingChange(e:Event):void{
			photoAlbumPost.apply(this, lastPhotoArgs); 
			removeEventListener(SocialAdapter.EVENT_PERMISSION_CHANGED, onPhotoSettingChange);
		}
		
		private var lastStatusArgs:Array;
		override public function setStatus(status:String, onComplete:Function, onError:Function, link:String = null, title:String = null):void{
			wallPostJS(null, onComplete, onError, status);
			/*
			if(PERMISSION_STATUS){
				// статусим
				lastStatusArgs = null;
				//_sendRequest("notes.add", {"title":(title?title:(status.length > 18?status.substr(0,15) + "...":status)), "text": status}, onComplete, onError);
				_sendRequest("activity.set", {"text": status, "uid": flashVars["viewer_id"]}, onComplete, onError);
			}else{
				removeEventListener(SocialAdapter.EVENT_PERMISSION_CHANGED, onStatusSettingChange);
				addEventListener(SocialAdapter.EVENT_PERMISSION_CHANGED, onStatusSettingChange);
				lastStatusArgs = arguments;
				showSettingsBox(PERMISSION_STATUS_MASK);
			}
			*/
		}
		private function onStatusSettingChange(e:Event):void{setStatus.apply(this, lastStatusArgs); removeEventListener(SocialAdapter.EVENT_PERMISSION_CHANGED, onStatusSettingChange);}
		
		override protected function _isAppUser():Boolean{
			return flashVars["is_app_user"] == 1;
		}
		
		protected var forExecution:Array = [];// очередь на execute при ините
		override protected function _startInitLoading():void{			
			if(flashVars["api_result"] != null && flashVars["api_result"] != "" )
				_initData = JSON.decode(flashVars["api_result"]).response;
			
			if(_initData.user==null){
				forExecution.push('"user":API.getProfiles({"uids":' + flashVars["viewer_id"] + ',"fields":"uid,first_name,last_name,nickname,sex,bdate,photo,photo_medium,photo_big,has_mobile,rate"})');
			}else{
				_initData.user = _initData.user[0];
				if(_initData.city && _initData.city[0])
				{
					_initData.user.city = _initData.city[0].name;
					_initData.user.cityCode = _initData.city[0].cid;
				}
				if(_initData.country && _initData.country[0])
				{
					_initData.user.country = _initData.country[0].name;
					_initData.user.countryCode = _initData.country[0].cid;
				}
			}
			
			if(_initData.friends==null)
				forExecution.push('"friends":API.getProfiles({"uids":API.getFriends(),"fields":"uid,first_name,last_name,photo,photo_medium,sex"})');
			
			if(_initData.appFriends==null)
				forExecution.push('"appFriends":API.getAppFriends()');
			
			if(_initData.balance==null)
				forExecution.push('"balance":API.getUserBalance()');
			
			if(_initData.groups==null)
				forExecution.push('"groups":API.getGroups()');
			
			if(forExecution.length)
				execute('return{' + forExecution.join() + '};'	,onInitExecutionComplete, onInitExecutionError);
			else
				_checkInitLoadingCompletion();
		}
		
		protected function onInitExecutionComplete(data:Object):void{
			if(data.user!=null)
				_initData.user = data.user[0];
			if(data.friends!=null)
				_initData.friends = data.friends as Array || [];
			if(data.appFriends!=null)
				_initData.appFriends = data.appFriends as Array || [];
			if(data.balance!=null)
				balance = data.balance * 0.01;
			if(data.groups!=null) {
				_initData.groups = data.groups as Array || [];
			} 
			_checkInitLoadingCompletion();
		}
		
		protected function onInitExecutionError(e:Object):void{
			onInitError && onInitError();
		}
		
		
		
		override protected function _getApiUrl(method:String, request:Object=null):String{
			return flashVars["api_url"]?flashVars["api_url"]:"http://api.vkontakte.ru/api.php";
		}
		
		override protected function _getUrlVariables(method:String):URLVariables{ 	
			var urlVariables:URLVariables = new URLVariables;
			urlVariables["method"] = method;
			urlVariables["api_id"] = flashVars["api_id"];
			urlVariables["format"] = "JSON";
			urlVariables["v"] = "3.0";
			return urlVariables;
		}
		
		// {"name":Паша, "age":23, "male":1}
		override protected function _createSignature(urlVariables:Object):void{
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
			//urlVariables["access_token"] = flashVars["access_token"];
		}
		
		/**
		 * Осуществляет посылку запросов не чаще, чем 3 раза в секунду
		 */
		override protected function _sendRequest(method:String, request:Object=null, onComplete:Function=null, onError:Function=null, GET:Boolean=false):void
		{
			// запас устойчивости к случайным ошибкам "Too many requests per second"
			const margin:Number = 1.2;
			
			var currentTime:Number = getTimer();
			var currentSec:int = currentTime * 0.001;
			
			if(currentSec > lastRequestSecond)
			{
				// новая секунда настала, можно слать
				lastRequestSecond = currentSec;
				lastRequestCounter = 0;
			}else{
				lastRequestCounter++;
			}
			
			if(lastRequestCounter > 2 || (currentTime - lastRequestTime) < 200 * margin)// число 200 найдено опытным путем
			{
				if(sendRequestTimer == null)
				{
					sendRequestTimer = new Timer(400 * margin);// число 400 найдено опытным путем
					sendRequestTimer.addEventListener(TimerEvent.TIMER, onSendRequestTimer);
				}
				pendingRequests.push({"args": arguments, "time": currentSec});
				if(sendRequestTimer.running)
					lastRequestFailed = true;
				else
					sendRequestTimer.start();
				
				return;
			}
			
			lastRequestTime = currentTime;

            // также, обрабатываем ошибку с test_mode
            if(useTestMode)
            {
                if(request == null) request = {};
                request['test_mode'] = 1;
            }

			super._sendRequest(method, request, onComplete, function(error:Object):void{
                if(error && error.hasOwnProperty('error') && error.error.hasOwnProperty('error_code') && error.error.error_code == 2 && useTestMode == false)
                {
                    useTestMode = true;
                    _sendRequest(method, request, onComplete, onError, GET)
                }
                else
                    if(onError != null)
                        onError(error);
            }, GET);
		}
		
		private var lastRequestSecond:int;// секунда отсылки последнего запроса
		protected var lastRequestCounter:int;// скольк запросов было послано в текущую секунду
		private var lastRequestTime:Number = 0;// точное время отсылки последнего запроса 
		private var pendingRequests:Array = [];// array of {args:Array, time:uint}
		private var sendRequestTimer:Timer;
		private var lastRequestFailed:Boolean;
		private function onSendRequestTimer(e:Event):void
		{
			lastRequestFailed = false;
			if(pendingRequests.length)
			{
				var item:Object = pendingRequests.shift();
				_sendRequest.apply(this, item.args);
				
				if(lastRequestFailed)
				{
					// ставим последний элемент в начало - на его заслуженное место, перед началом работы текущей функции
					if(pendingRequests[pendingRequests.length - 1] == item)
						pendingRequests.unshift(pendingRequests.pop());
				}
			}
			
			if(pendingRequests.length == 0)
				sendRequestTimer.stop();
		}
		
		
		override protected function _responseHandler(response:String, onComplete:Function, onError:Function):Boolean{
			if(super._responseHandler(response, onComplete, onError)){
				var serverResponce:Object = _safetyJSONDecode(response, onError);
				if(serverResponce){
					if(serverResponce.error){
						
						if(serverResponce.error.hasOwnProperty("error_code"))
						{
							switch(serverResponce.error.error_code)
							{
								case 3:// Unknown method passed
								case 4:// Incorrect signature: server authorization, ifame\/flash authorization
										dispatchEvent(new Event(EVENT_AUTHORIZATION_ERROR));
										break;
								case 6:
										// приостановить следующие запросы
										lastRequestCounter += 10;
										break;
							}
						}
						
						onError && onError(serverResponce);						
					}else{
						onComplete && onComplete(serverResponce?serverResponce.response:null);
						return true;
					}
				}else{
					onError && onError({error:"JSON parsing error"});		
				}
			}
			return false;
		}
		
		//////////////////////////////////////////////////////
		//
		//					PRIVATE
		//
		//////////////////////////////////////////////////////
		
		
		// листенер на событие wrapper
		protected function onSettingsChanged(e:Object):void{
			wrapper.removeEventListener("onApplicationAdded", onSettingsChanged);
			flashVars["api_settings"] = PERMISSIONS = e.settings;
			dispatchEvent(new Event(SocialAdapter.EVENT_PERMISSION_CHANGED));
		}
		
		// изменен баланс по событию враппера (или по запросу к api)
		protected function onBalanceChanged(e:Object):void{
			balance = e.balance * 0.01;
			dispatchEvent(new Event("onBalanceChanged"));
		}
		
		
		
		//////////////////////////////////////////////////////
		//
		//			Эмуляция класса WallPostManager 
		//		который публикует посты на стену вконтакте
		//
		//////////////////////////////////////////////////////
		private var wallPostManager_wallPhoto:Boolean;
		private var wallPostManager_onComplete:Function;
		private var	wallPostManager_onError:Function;
		protected var wallPostManager_image:BitmapData;
		private var wallPostManager_recipient_id:String;
		private var wallPostManager_message:String;
		private var wallPostManager_post_id:String;
		protected var wallPostManager_album:Object;
		protected var wallPostManager_albums : Array;
		protected function wallPostManager_save(album:Object, imageBmpData:BitmapData, message:String, recipient_id:String, postData:String):void{
			if(wallPostManager_image)
				wallPostManager_image.dispose();
			
			wallPostManager_album = album;
			wallPostManager_image = imageBmpData;
			wallPostManager_message = message;
			wallPostManager_recipient_id = recipient_id;
			wallPostManager_post_id = postData;
			
			if(album) {
				album.privacy = 0;
				album.comment_privacy = 0;
				wallPostManager_getAlbums();				
			}
			else
				wallPostManager_getPhotoUploadServer();
		}
		
		protected function wallPostManager_getNotes() : void {
			if(PERMISSION_WALL_USER) {
				
			}
		}
		
		protected function wallPostManager_getAlbums() : void {	
			_sendRequest("photos.getAlbums", null, function(e:Object):void{
				wallPostManager_albums = e as Array;
				if (wallPostManager_albums){
					if (wallPostManager_album) {
						for each(var obj : Object in wallPostManager_albums) {
							if(obj.title == wallPostManager_album.title) {
								wallPostManager_album.aid = obj.aid;
								break;
							}
						}
						if(!wallPostManager_album.aid) {
							wallPostManager_createAlbum(wallPostManager_album);
							return;
						}
					} 
					wallPostManager_getPhotoUploadServer();
					return;
				} else {
					wallPostManager_createAlbum(wallPostManager_album);
					return;
				}
				wallPostManager_onError && wallPostManager_onError();
			}, function(e:Object):void{
				wallPostManager_onError && wallPostManager_onError();
			});
		}
		
		private function wallPostManager_createAlbum(album : Object) : void {
			_sendRequest("photos.createAlbum", album, function(e:Object):void{
				if (e.hasOwnProperty("aid")){
					if (wallPostManager_album){
						if(wallPostManager_albums) {
							wallPostManager_albums.push(e);
						}
						wallPostManager_album.aid = e.aid;
					}
					wallPostManager_getPhotoUploadServer();
					return;
				}
				wallPostManager_onError && wallPostManager_onError();
			}, function(e:Object):void{
				wallPostManager_onError && wallPostManager_onError();
			});
		}
		
		private function wallPostManager_getPhotoUploadServer():void{
			_sendRequest(wallPostManager_album?"photos.getUploadServer":"wall.getPhotoUploadServer", wallPostManager_album, function(e:Object):void{
				if (e.hasOwnProperty("upload_url")){					
					wallPostManager_savePhoto(e["upload_url"]);
					return;
				}
				wallPostManager_onError && wallPostManager_onError();
			}, function(e:Object):void{
				wallPostManager_onError && wallPostManager_onError();
			});
		}
		
		protected function wallPostManager_savePhoto(upload_url:String):void{
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
			
			var saver:URLLoader = new flash.net.URLLoader();
			saver.addEventListener(Event.COMPLETE, wallPostManager_onSavePhotoComplete);
			saver.load(request);
		}
		
		protected function wallPostManager_onSavePhotoComplete(e:Event):void{
			e.currentTarget.removeEventListener(Event.COMPLETE, wallPostManager_onSavePhotoComplete);
			var response:Object;
			var request:Object;
			response = JSON.decode(e.target.data);
			
			if(wallPostManager_wallPhoto) {
				if(response.hasOwnProperty('hash') && response.hasOwnProperty('photo') &&response.hasOwnProperty('server')) {
					_sendRequest("photos.saveWallPhoto",{server:response.server,photo:response.photo,hash:response.hash}, wallPostManager_wallPhotoSaveComplete, function(e:Object):void{
						wallPostManager_onError && wallPostManager_onError();
					});
				} 
				return;
			} else if (wallPostManager_album) {// сохранить в альбом
				if (response.hasOwnProperty("aid") && response.hasOwnProperty("server") && response.hasOwnProperty("photos_list") && response.hasOwnProperty("hash"))
					if (String(response["photos_list"]).length > 0)
					{
						_sendRequest("photos.save",{aid:response.aid, server:response.server, photos_list:response.photos_list, hash:response.hash}, wallPostManager_albumPhotoSaveComplete, function(e:Object):void{
							wallPostManager_onError && wallPostManager_onError();
						});
						return;  
					}
			} else {
				// сохранить на сервер для публикации на стену
				if (wallPostManager_album == null){
					wallPostManager_albumPhotoSaveComplete([response]);
					return;
				}
			}
			wallPostManager_onError && wallPostManager_onError();
		}
		
		private function wallPostManager_wallPhotoSaveComplete(data:Object):void {
			if(data is Array && data[0]) {
				var id : String = data[0].id;
				wallPostJS(null,wallPostManager_onComplete, wallPostManager_onError, wallPostManager_message, id);
			} else {
				wallPostManager_onError && wallPostManager_onError();
			}
		}
		
		private function wallPostManager_albumPhotoSaveComplete(e:Array):void{
			var response:Object = e[0];			
			if (wallPostManager_album){
				wallPostManager_album["src"] = response["src_big"];
				dispatchEvent(new Event("connect"));
			}
			var request:Object;
			if (response.hasOwnProperty("server") && response.hasOwnProperty("photo") && response.hasOwnProperty("hash")){
				if(String(response["photo"]).length > 0)
				{
					request = {server: response.server, photo: response.photo, hash: response.hash};
					request.message = wallPostManager_message;
					request.wall_id = wallPostManager_recipient_id;
					request.post_id = wallPostManager_post_id;
					_sendRequest("wall.savePost", request, wallPostManager_onSavePostComplete, function(e:Object):void{
						wallPostManager_onError && wallPostManager_onError();
					});
				}
			} else {
				if(response.hasOwnProperty("pid") && response.hasOwnProperty("aid") && response.hasOwnProperty("owner_id")){
					wallPostManager_onComplete && wallPostManager_onComplete(response);				
				} else {
					wallPostManager_onError && wallPostManager_onError();
				}
			}			
		}
		
		protected function wallPostManager_onSavePostComplete(e:Object):void{
			if(wrapper){				
				wrapper.addEventListener("onWallPostSave", wallPostManager_onWallPostSave);
				wrapper.addEventListener("onWallPostCancel", wallPostManager_onWallPostCancel);
				wrapper.external.saveWallPost(e.post_hash);
				return;
			}
			wallPostManager_onError && wallPostManager_onError();
		}
		
		protected function wallPostManager_onWallPostSave(e:Object):void{
			wrapper.removeEventListener("onWallPostSave", wallPostManager_onWallPostSave);
			wrapper.removeEventListener("onWallPostCancel", wallPostManager_onWallPostCancel);
			wallPostManager_onComplete && wallPostManager_onComplete();
		}
		
		protected function wallPostManager_onWallPostCancel(e:Object):void{
			wrapper.removeEventListener("onWallPostSave", wallPostManager_onWallPostSave);
			wrapper.removeEventListener("onWallPostCancel", wallPostManager_onWallPostCancel);
			wallPostManager_onError && wallPostManager_onError();
		}
	}
}
