package com.somewater.arrow {
	import com.adobe.serialization.json.JSON;
	import com.somewater.arrow.ArrowEvent;
	import com.somewater.social.SocialUser;
	import com.somewater.social.SocialUser;
	import com.somewater.social.SocialUser;

	import flash.display.DisplayObject;
	import flash.events.EventDispatcher;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.SecurityErrorEvent;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.net.URLRequestMethod;
	import flash.net.URLVariables;
	import flash.utils.getQualifiedSuperclassName;

	public class ArrowBase extends EventDispatcher implements IArrow{

		protected var initParams:Object;
		protected var initData:Object = {"user":null,"friends":null,"appFriends":null};// хранилище загруженных данных, ждущих парсинга

		protected var initLoadingStarted:Boolean = false;
		protected var initLoadingCompleted:Boolean = false;

		/**
		 * Считаем, что  все пермишны выставлены
		 */
		protected var permissions:uint = 1 | ArrowPermission.USER_PROFILE | ArrowPermission.FRIENDS_PROFILES | ArrowPermission.NOTIFY;

		protected var usersById:Array = [];
		protected var friendsById:Array = [];
		protected var appFriendsById:Array = [];
		protected var me:SocialUser;
		protected var _flashVars:Object;

		public function ArrowBase() {
		}

		public function get flashVars():Object {
			return _flashVars;
		}

		public function get key():String {
			return initParams['key'];
		}

		public function init(params:Object):void {
			initParams = params;

			var flashVarsHolder:Object = params['stage'] || params['flashVars'];
			if (flashVarsHolder is DisplayObject && getQualifiedSuperclassName(flashVarsHolder) == "mx.core::Application")
				flashVarsHolder = flashVarsHolder.parameters;
			else{
				if(flashVarsHolder["loaderInfo"] != null && (flashVarsHolder is DisplayObject))
					if(flashVarsHolder["loaderInfo"]["parameters"] != null)
						flashVarsHolder = flashVarsHolder["loaderInfo"]["parameters"];
			}
			_flashVars = flashVarsHolder;

			if(params['autoStart'] != false)
				connectToApi();
		}

		final public function get hasUserApi():Boolean {
			return Boolean(hasPermissions & ArrowPermission.USER_PROFILE);
		}

		final public function get hasFriendsApi():Boolean {
			return Boolean(hasPermissions & ArrowPermission.FRIENDS_PROFILES);
		}

		final public function get hasPaymentApi():Boolean {
			return Boolean(hasPermissions & ArrowPermission.PAYMENT);
		}

		final public function getFriends():Array {
			var arr:Array = [];
			for each(var f:SocialUser in friendsById)
				arr.push(f);
			return arr;
		}

		final public function getAppFriends():Array {
			var arr:Array = [];
			for each(var f:SocialUser in appFriendsById)
				arr.push(f);
			return arr;
		}

		final public function getUser():SocialUser {
			return me;
		}

		public function showInviteWindow():void {
			throw new Error('Override me');
		}

		public function pay(quantity:Object, onSuccess:Function, onFailure:Function, params:Object = null):void {
			throw new Error('Override me');
		}

		final public function getUsers(uids:Array, onComplete:Function, onError:Function):void {
			var i:int;

			// посмотреть в users
			var cache:Array = [];
			for(i = 0;i<uids.length;i++)
				if(usersById[uids[i]] != null){
					cache.push(usersById[uids[i]]);
					uids.splice(i, 1);
					i--;
				}

			if(uids.length){
				getUserProfiles(uids, function(event:ArrowEvent):void{
					var socialUsers:Array = [];
					var array:Array = event.response as Array;
					for(var i:int;i<array.length;i++){
						var su:SocialUser = array[i] is SocialUser ? array[i] : createSocialUser(array[i])
						socialUsers.push(su);
						addSocialUser(su);
					}
					// соединить с cash и передать заинтересованной функции
					event.response = socialUsers.concat(cache)
					onComplete(event);
				}, onError);
			}else{
				// все пользователи получены из кэша
				var ev:ArrowEvent = new ArrowEvent(ArrowEvent.REQUEST_SUCCESS);
				ev.response = cache;
				onComplete(ev);
			}
		}

		public function posting(user:SocialUser = null, title:String = null, message:String = null, image:* = null, imageUrl:String = null, data:String = null, onComplete:Function = null, onError:Function = null, additionParams:Object = null):void {
			throw new Error('Override me');
		}

		final public function getCachedUser(uid:String):SocialUser {
			if(me && me.id == uid)
				return me;
			else
				return usersById[uid];
		}

		public function setPermissions(required:uint = 0):void {
		}

		public function get hasPermissions():uint {
			return 0;
		}

		public function installApp(requredPermissions:uint = 0):void {
		}

		public function get netId():int
		{
			return 1;
		}

		public function jsonDecode(string:String):Object
		{
			return JSON.decode(string);
		}

		public function jsonEncode(object:Object):String
		{
			return JSON.encode(object);
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
		protected function connectToApi():void
		{
			refresh();// сразу запускаем инициализацию
		}

		/**
		 * Выполнить инициализационные проверки и перейти к загрузке
		 * @param обеспечивает принятие любых параметров (например MouseEvent) или никаких (параметры не должны обрабатываться)
		 */
		protected function refresh(...args):void{
			if(initLoadingStarted) return;
			if(appInstalled()){
				if(checkPermission()){
					initLoadingStarted = true;
					startInitLoading();
				}else{
					onRefreshAbstractError(ArrowEvent.PERMISSION_CHANGED, ArrowEvent.PERMISSION_ERROR, setPermissions);
				}
			}else{
				onRefreshAbstractError(ArrowEvent.APP_INSTALLED, ArrowEvent.INSTALL_APP_ERROR, installApp);
			}
		}// end refresh

		private function onRefreshAbstractError(changeEventType:String, errorEventType:String, showPopup:Function):void{
			// повесить листенер на изменение состояния (которое послужило причиной ошибки)
			removeEventListener(changeEventType, onRefresh);// на случай, если листенер уже был добавлен
			addEventListener(changeEventType, onRefresh);
			// отправить событие о текущей ошибке, если для события не был вызван метод event.preventDefault(), вызвать окно соц. сети
			if(dispatchEvent(new ArrowEvent(errorEventType)))
				showPopup();
		}


		private function onRefresh(e:Event):void{
			removeEventListener(e.type, onRefresh);
			refresh();
		}

		protected function startInitLoading():void{
			throw new Error('Override me');
//			loadUserProfile(function(e:Object):void{
//				_initData["user"] = e;
//				_checkInitLoadingCompletion();
//			});
//			loadUserFriendsProfiles(function(e:Object):void{
//				_initData["friends"] = e;
//				_checkInitLoadingCompletion();
//			});
//			loadUserAppFriends(function(e:Object):void{
//				_initData["appFriends"] = e;
//				_checkInitLoadingCompletion();
//			});
		}

		/**
		 *
		 * @return были получены все необходимые данные для инициализации. В этом случае запускается _parceInitData();
		 *
		 */
		protected function checkInitLoadingCompletion():Boolean{
			if(initData.user !== null && initData.friends !== null && initData.appFriends !== null){
				parseInitData();
				return true;
			}
			return false;
		}

		// обработать данные, полученные на этапе инициализации от сервера соц. сети
		// предполагается, что _initData = {user:{ профиль },   appFriendsIds:[  массив id app-друзей ]   ,    friends:[ массив профилей друзей  ]  }
		// после завершения парсинга, вызвать onInitComplete();
		protected function parseInitData():void{
			var i:int;
			if(!(initData.friends is Array)) initData.friends = [];
			if(!(initData.appFriends is Array)) initData.appFriends = [];

			// перевести массив типа [1, 3, 6] в массив типа ["1", "3", "6"] - т.к. id юзеров  у нас сугубо String
			var tempAppFriendsIds:Array = initData.appFriends;
			for(i = 0;i<tempAppFriendsIds.length;i++)
				tempAppFriendsIds[i] = String(tempAppFriendsIds[i]);

			for(i = 0;i<initData.friends.length;i++){
				var friend:SocialUser = createSocialUser(initData.friends[i]);
				var appFrienIndex:int = tempAppFriendsIds.indexOf(friend.id);
				if(appFrienIndex != -1)
				{
					friend.isAppFriend = true;
					tempAppFriendsIds.splice(appFrienIndex, 1);
				}
				friend.isFriend = true;
				addSocialUser(friend);
			}
			me = createSocialUser(initData.user);
			me.itsMe = true;
			addSocialUser(me);

			if(tempAppFriendsIds.length)
			{
				// послать еще запрос
				getUserProfiles(tempAppFriendsIds, function(resp:ArrowEvent):void{
					var missing:Array = resp.response['response'];
					if(missing == null) missing = [];
					for(var j:int = 0;j<missing.length;j++)
					{
						var s:SocialUser = missing[j] is SocialUser ? missing[j] : createSocialUser(missing[j]);
						s.isAppFriend = true;
						s.isFriend = true;
						addSocialUser(s);
					}
					onInitDataParsed();
				}, function(error:Object):void{
					// загружаемся без части апп юзеров
					onInitDataParsed();
				});
			}else
			{
				onInitDataParsed();
			}
		}

		private function onInitDataParsed():void {
			initLoadingCompleted = true;
			dispatchEvent(new ArrowEvent(ArrowEvent.INITED));
			(initParams['complete'] is Function) && initParams['complete']();
		}

		/**
		 * Действительно обратиться к соц сети за профайлами
		 * возвратить ArrowEvent.response as array of SocialUser
		 */
		protected function getUserProfiles(uids:Array, onComplete:Function, onError:Function):void
		{
			throw new Error('Override me');
		}

		protected function addSocialUser(user:SocialUser):void
		{
			if(user.itsMe)
				me = user;
			if(user.isFriend)
				friendsById[user.id] = user;
			if(user.isAppFriend)
				appFriendsById[user.id] = user;
			usersById[user.id] = user;
		}

		/**
		 * Сериализовать объект в данные соц. сети
		 */
		protected function createSocialUser(data:Object):SocialUser
		{
			throw new Error('Override me');
		}


		/**
		 *
		 * @param method
		 * @param params
		 * @param onComplete
		 * @param onError
		 * @param flags
		 * 			- get
		 */
		public function call(method:String, params:Object = null, onComplete:Function = null, onError:Function = null, flags:Object = null):void
		{
			params ||= {};
			flags ||= {};

			var urlRequest:URLRequest = new URLRequest();
			urlRequest.method = flags['get']?URLRequestMethod.GET:URLRequestMethod.POST;
			urlRequest.url = getApiPath(method, params, flags);

			var urlVariables:URLVariables = getUrlVariables(method, params, flags);

			postprocessParams(urlVariables);

			var urlLoader:URLLoader = new URLLoader();
			urlLoader.addEventListener(Event.COMPLETE, onLoaderComplete);
			urlLoader.addEventListener(IOErrorEvent.IO_ERROR, onIOError);
			urlLoader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, onSecurityError);

			urlRequest.data = urlVariables;

			urlLoader.load(urlRequest);

			function onLoaderComplete(e:Event):void{
				clearLoader(e.target as URLLoader);
				// передать данные от сервера отдельной функции-обработчику
				responseHandler(e.target.data, method, params, onComplete, onError, flags);
			}

			function onIOError(e:IOErrorEvent):void{
				clearLoader(e.target as URLLoader);
				fireApiRequestEvent(onError, method, params, flags, null, ArrowError.IO_ERROR);
			}

			function onSecurityError(e:SecurityErrorEvent):void{
				clearLoader(e.target as URLLoader);
				fireApiRequestEvent(onError, method, params, flags, null, ArrowError.SECURITY_ERROR);
			}
			// очистка от всех листенеров
			function clearLoader(loader:URLLoader):void{
				loader.removeEventListener(Event.COMPLETE, onLoaderComplete);
				loader.removeEventListener(IOErrorEvent.IO_ERROR, onIOError);
				loader.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, onSecurityError);
			}
		}

		protected function fireApiRequestEvent(callback:Function, method:String, params:Object, flags:Object, response:Object = null, error:String = null):void
		{
			var event:ArrowEvent = new ArrowEvent(error ? ArrowEvent.REQUEST_ERROR : ArrowEvent.REQUEST_SUCCESS);
			event.error = error;
			event.method = method;
			event.params = params;
			event.flags = flags;
			event.response = response;
			event.error = error;
			dispatchEvent(event);
			callback(event);
		}

		protected function getUrlVariables(method:String, params:Object, flags:Object):URLVariables
		{
			var uv:URLVariables = new URLVariables();
			if(params)
				for(var name:String in params)
					uv[name] = params[name];
			return uv;
		}

		protected function getApiPath(method:String, params:Object, flags:Object):String
		{
			throw new Error('Override me');
		}

		protected function appInstalled():Boolean{
			throw new Error('Override me');
		}

		// пользователь разрешил необходимые нстройки (проверка на основе flashVars)
		protected function checkPermission(required:uint = 0):Boolean{
			if(!required)
				required = ArrowPermission.DEFAULT;
			var highBit:int = int(Math.log(required)/Math.LN2);
			for(var i:int = 0; i <= highBit; i++)
				if(required & (1 << i))// если данный разряд requiredVkPermission имеет "1"
					if(!(permissions & (1 << i)))
						return false;
			return true;
		}

		/**
		 * Создать подпись запроса (если в этом есть необходимость для текущей соц. сети)
		 */
		protected function postprocessParams(urlVariables:URLVariables):void{

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
		protected function responseHandler(response:String, method:String, params:Object = null, onComplete:Function = null, onError:Function = null, flags:Object = null):Object{
			if(response == null || response == ""){
				fireApiRequestEvent(onError, method, params, flags, null, ArrowError.EMPTY_RESPONSE)
			}else{
				try{
					var responseData:Object = deserialize(response);
					if(responseData == null || responseData === "" || responseData === "null")
						fireApiRequestEvent(onError, method, params, flags, null, ArrowError.EMPTY_RESPONSE)
					else
						return responseData;
				}catch(e:Error){
					fireApiRequestEvent(onError, method, params, flags, null, ArrowError.RESPONSE_FORMAT_ERROR)
				}
			}
			return null;
		}

		protected function deserialize(string:String):Object{
			return jsonDecode(string);
		}
		protected function serialize(data:Object):String{
			return jsonEncode(data);
		}
	}
}
