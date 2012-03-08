package com.somewater.social
{
	import com.adobe.crypto.MD5;
	import com.adobe.serialization.json.JSON;
	
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.errors.IOError;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.events.SecurityErrorEvent;
	import flash.events.TimerEvent;
	import flash.geom.Rectangle;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.net.URLRequestMethod;
	import flash.net.URLVariables;
	import flash.utils.Dictionary;
	import flash.utils.Timer;
	import flash.utils.getQualifiedSuperclassName;
	
	
	
	[Event (name="eventInstallAppError", type="com.somewater.social.SocialAdapter")]// приложение не установлено
	
	[Event (name="eventInstallAppComplete", type="com.somewater.social.SocialAdapter")]// приложение было установлено
	
	[Event (name="eventPermissionError", type="com.somewater.social.SocialAdapter")]// настройки приложения не соответствуют требуемым
	
	[Event (name="eventPermissionChanged", type="com.somewater.social.SocialAdapter")]// настройки приложения были изменены
	
	[Event (name="eventCloseAlertPopup", type="com.somewater.social.SocialAdapter")]// нужно закрыть Popup "установи приложение"/"разреши настройки" если таковые были открыты
	
	[Event (name="eventLocationChanged", type="com.somewater.social.SocialAdapter")]// получены (или изменены) данные о #hash страницы. Смотреть новое значение в socialAdapter.location:*
	
	[Event (name="eventAuthorizationError", type="com.somewater.social.SocialAdapter")]// api соц. сети вернуло ошибку, связанное с отсутствием авторизации, пользователю надо авторизоваться еще раз
	
	/**
	 * Абстрактный класс для работы с API и JS/Flash обертками 
	 * Вся логика работы с соцсетями должна быть реализована внутри наследников
	 * 1) При написании реализации, на основе текущего класса, переопределить (при необходимости) следующие функции:
	 * 		createSocialUser
	 *		loadProfiles
	 *		loadUserProfile
	 *		loadUserFriends
	 *		loadUserAppFriends
	 *		loadUserBalance
	 *		showInstallBox
	 *		showSettingsBox
	 *		showInviteBox
	 * 		_isAppUser
	 * 		_startInitLoading
	 * 		_checkInitLoadingComplete
	 * 		_parceInitData
	 * 		_getApiUrl
	 * 		_getUrlVariables
	 * 		_createSignature
	 * 		_responseHandler
	 * 
	 * 	Переопределить при необходимости:
	 * 		init (если flashVars специфически находятся или обрабатываются)
	 * 		_startInitLoading
	 * 		wallPost (если функция поддерживается соц. сетью)
	 * 		_checkPermission (если permission имеют отличный от битовых масок вид)
	 * 		_checkInitLoadingComplete
	 * 		_parceInitData
	 * 		
	 * 2) переопределить PERMISSION_..._MASK в конструкторе
	 * 4) записать secret_keys в констукторе (или применить их способом, принятым в конкретной соц. сети)
	 * 3) задокументировать нестандартные способы вызова функций :) (например flashVars в vk wrapper)
	 * 4) повесить специфичные для соц. сети листенеры и диспатчить по ним предусмотренные события класса
	 */
	public class SocialAdapter extends EventDispatcher
	{
		public static var instance:SocialAdapter;
		
		/**
		 * Номер соц. сети
		 */
		public function get networkId():int{
			throw new Error("Must be overridden");
		}
		
		
		// идентификатор события инициализации, когда приложение не установлено на страницу (на событие открыть попап с кнопкой, по нажатию которой вызывается socialAdapter.refresh())
		public static const EVENT_INSTALL_APP_ERROR:String = "eventInstallAppError";
		
		// идентификатор события инициализации, когда приложение было установлено на страницу пользователя
		public static const EVENT_INSTALL_APP_COMPLETE:String = "eventInstallAppComplete";
		
		// идентификатор события инициализации, когда приложению не разрешены требуемые настройки (на событие открыть попап с кнопкой, по нажатию которой вызывается socialAdapter.refresh())
		public static const EVENT_PERMISSION_ERROR:String = "eventPermissionError";
		
		// идентификатор события инициализации, когда настройки приложения были изменены
		public static const EVENT_PERMISSION_CHANGED:String = "eventPermissionChanged";
		
		// идентификатор события, когда приложение должно закрыть все Popup (ранее открытые по событиям EVENT_INSTALL_APP_ERROR или EVENT_PERMISSION_ERROR)
		public static const EVENT_CLOSE_ALERT_POPUPS:String = "eventCloseAlertPopup";
		
		// идентификатор события, когда стал известен #hash страницы, либо он был изменен (хранится в socialAdapter.location)
		public static const EVENT_LOCATION_CHANGED:String = "eventLocationChanged";
		
		// сошл адаптер был инициализован (вызывается перед вызовом callback на init)
		public static const EVENT_INITED:String = "eventInited";
		
		// api соц. сети вернуло ошибку, связанное с отсутствием авторизации, пользователю надо авторизоваться еще раз
		public static const EVENT_AUTHORIZATION_ERROR:String = "eventAuthorizationError";
		
		/**
		 * Настройки разрешений. Если функции API не существует, маска равна нулю
		 */
		public var DEFAULT_PERMISSION_MASK:int;// какие настройки просим установить
		public var MANDATORY_PERMISSION_MASK:int;// без каких настроек не пускаем в игру
		public var PERMISSIONS:int = 0;// можно переопределять перед вызовом init();
		
		internal var PERMISSION_NOTIFICATION_MASK:int = 0;
		internal var PERMISSION_FRIENDS_MASK:int = 0;
		internal var PERMISSION_PHOTO_MASK:int = 0;
		internal var PERMISSION_WALL_USER_MASK:int = 0;// можно постить на стену самому себе
		internal var PERMISSION_WALL_FRIEND_MASK:int = 0;// можно постить на стену другу
		internal var PERMISSION_WALL_APPFRIEND_MASK:int = 0;// можно постить на стену app-другу
		public var PERMISSION_BOOKMARK_MASK:int = 0;
		internal var PERMISSION_STATUS_MASK:int = 0;
		internal var PERMISSION_NOTES_MASK:int=0
		public var PERMISSION_WALL_GET_MASK:int=0;
		/** Поддерживается ли ресайз флэшки на рантайме */
		public var CAN_RESIZE:Boolean=false;
		
		
		/**
		 * Разрешения
		 */
		public function get PERMISSION_NOTIFICATION():Boolean { return Boolean(PERMISSIONS & PERMISSION_NOTIFICATION_MASK); }// разрешены нотификации (серверные)
		public function get PERMISSION_FRIENDS():Boolean { return Boolean(PERMISSIONS & PERMISSION_FRIENDS_MASK); }// разрешен запрос информации о друзьях
		public function get PERMISSION_PHOTO():Boolean { return Boolean(PERMISSIONS & PERMISSION_PHOTO_MASK); }// разрешена публикация в альбом
		public function get PERMISSION_WALL_USER():Boolean { return Boolean(PERMISSIONS & PERMISSION_WALL_USER_MASK); }// разрешено постить себе
		public function get PERMISSION_WALL_FRIEND():Boolean { return Boolean(PERMISSIONS & PERMISSION_WALL_FRIEND_MASK); }// разрешено постить другу
		public function get PERMISSION_WALL_APPFRIEND():Boolean { return Boolean(PERMISSIONS & PERMISSION_WALL_APPFRIEND_MASK); }// разрешено постить app-другу
		public function get PERMISSION_BOOKMARK():Boolean { return Boolean(PERMISSIONS & PERMISSION_BOOKMARK_MASK); }// разрешено добавить в закладки
		public function get PERMISSION_STATUS():Boolean { return Boolean(PERMISSIONS & PERMISSION_STATUS_MASK); }// разрешено менять статус пользователя (кототкое сообщение)
		public function get PERMISSION_NOTES():Boolean {return Boolean(PERMISSIONS & PERMISSION_NOTES_MASK);}// разрешено постить заметки
		public function get PERMISSION_WALL_GET():Boolean {return Boolean(PERMISSIONS & PERMISSION_WALL_GET_MASK);}// разрешено смотреть содержимое стены
		
		
		// можно ли постить на стену конкретному юзеру (учитывая настройки приложения)
		public function PERMISSION_WALL_FOR(socialUser:SocialUser):Boolean{
			if(socialUser.itsMe && PERMISSION_WALL_USER) return true;
			if(socialUser.isFriend && PERMISSION_WALL_FRIEND) return true;
			if(socialUser.isAppFriend && PERMISSION_WALL_APPFRIEND) return true;
			return false;
		}
		
		/**
		 * Наличие функций у соцсети
		 */		
		public function get HAS_NOTIFICATION():Boolean { return PERMISSION_NOTIFICATION_MASK!=0; }// поддерживаются нотификации (серверные)
		public function get HAS_PHOTO():Boolean { return PERMISSION_PHOTO_MASK!=0; }// поддерживается публикация фотографий в альбом
		public function get HAS_WALL_USER():Boolean { return PERMISSION_WALL_USER_MASK!=0; }// поддерживается постинг себе
		public function get HAS_WALL_FRIEND():Boolean { return PERMISSION_WALL_FRIEND_MASK!=0; }// поддерживается постинг другу
		public function get HAS_WALL_APPFRIEND():Boolean { return PERMISSION_WALL_APPFRIEND_MASK!=0; }// поддерживается постинг app-другу
		public function get HAS_BOOKMARK():Boolean { return PERMISSION_BOOKMARK_MASK!=0; }// поддерживается добавление в закладки
		public function get HAS_STATUS():Boolean { return PERMISSION_STATUS_MASK!=0; }// поддерживается изменение статуса (любого которкого сообщения  о пользователе)
		public function get HAS_NOTES():Boolean { return PERMISSION_NOTES_MASK!=0; }// поддерживается публикация заметок
		
		/**
		 * Информация о пользователях
		 */
		public var user:SocialUser;
		protected var users:Array = [];// все пользователи, данные о которых были загружены (возможно нужно иногда их чистить)
		protected var usersIds:Array = [];// массив id:String пользователей сети (для быстрого поиска типа if(usersIds.indexOf("245894") != -1){})
		protected var friends:Array = [];
		protected var friendsIds:Array = [];// массив id:String друзей пользователя
		protected var appFriends:Array = [];
		protected var appFriendsIds:Array = [];// массив id:String друзей по приложению
		internal var groups:Array = null;// массив идентификаторов групп, в которых состоит пользователь (если null значить соц. сеть не поддерживает получение подобной информации)
		
		
		protected var onInitComplete:Function;
		protected var onInitError:Function;
		// статус инициализации:  0 не начиналась, 1 была хоть раз запущена, 2 прошла проверку на appUser,
		// 3 прошла проверку на permissions(была начата инициализационная загрузка), 4 были заружены инициализационные данные (инициализация завершена)
		protected var initState:int = 0;
		public var autoRefresh:Boolean = true;// при init(...) автоматически запускается refresh(), которая начинает загрузку пользовательских данных
		public function get inited():Boolean{return initState == 4;}
		public function SocialAdapter():void {			
			if(instance)
				throw new Error("Singletone Class. Must be only one instance of SocialAdapter");
			
			// создать инстанс
			instance = this;
			
			// переопределяющие классы должны переопределить PERMISSION_..._MASK в конструкторе перед вызовом super
			MANDATORY_PERMISSION_MASK = PERMISSION_NOTIFICATION_MASK | PERMISSION_FRIENDS_MASK;
			DEFAULT_PERMISSION_MASK = MANDATORY_PERMISSION_MASK;
			// при необходимости, после super можно модифицировать MANDATORY_PERMISSION_MASK, DEFAULT_PERMISSION_MASK
		}
		
		/*****************************************************
		 * 
		 * Функции API, вызываемые при инициализации
		 * 
		 *****************************************************/
		
		/**
		 * Обеспечить загрузку инициализационных данных. После их успешной зарузки вызвать onComplete()
		 * @param network идентификатор сети
		 * @param flashVarsHolder непосредственно flashVars или ссылка на объект уровнями выше flashVars (для реализации vkontakte). См. описание в наследующем классе
		 * @param onComplete вызов после удачной инициализации
		 * @param onError вызов при ошибке инициализации onError(error:String = null)
		 * @param secret_keys ключи для осуществления работы с соц. сетью
		 */
		public function init(flashVarsHolder:Object, onComplete:Function, onError:Function = null, secret_keys:* = null):void {			
			if(initState > 0) return;
			initState = 1;
			// в переопределяющих функциях можно делат проверку, если network не соответствует реализации, выдать ошибку
			onInitComplete = onComplete;
			onInitError = onError;
			keys = secret_keys;
			// определить, является ли flashVarsHolder ссылкой на stage
			if (flashVarsHolder is DisplayObject && getQualifiedSuperclassName(flashVarsHolder) == "mx.core::Application")
				flashVarsHolder = flashVarsHolder.parameters;
			else{
				if(flashVarsHolder["loaderInfo"] != null && (flashVarsHolder is DisplayObject))
					if(flashVarsHolder["loaderInfo"]["parameters"] != null)
						flashVarsHolder = flashVarsHolder["loaderInfo"]["parameters"];
			}
			
			this.flashVars = flashVarsHolder;
			
			preRefresh();
			
			if(autoRefresh)
				refresh();
		}
		
		/**
		 * Выполняется перед вызовом refresh() и может оверрайдиться для специальной подготовки


		 * flashVars и других параметров
		 */
		protected function preRefresh():void{
			
		}
		
		/**
		 * Выполнить инициализационные проверки и перейти к загрузке
		 * @param обеспечивает принятие любых параметров (например MouseEvent) или никаких (параметры не должны обрабатываться)
		 */
		public function refresh(...args):void{
			if(initState > 2) return;
			// удалить всплывающие окна об ошибках (если такая функция реализована в приложении)
			dispatchEvent(new Event(SocialAdapter.EVENT_CLOSE_ALERT_POPUPS));
			if(_isAppUser()){
				initState = 2;
				if(_checkPermission()){
					initState = 3;
					_startInitLoading();
				}else{
					abstractError(EVENT_PERMISSION_CHANGED, EVENT_PERMISSION_ERROR, showSettingsBox);
				}
			}else{
				abstractError(EVENT_INSTALL_APP_COMPLETE, EVENT_INSTALL_APP_ERROR, showInstallBox);
			}
			
			function abstractError(changeEventType:String, errorEventType:String, showPopup:Function):void{
				// повесить листенер на изменение состояния (которое послужило причиной ошибки)
				removeEventListener(changeEventType, _onRefreshRequired);// на случай, если листенер уже был добавлен
				addEventListener(changeEventType, _onRefreshRequired);
				// отправить событие о текущей ошибке, если для события не был вызван метод event.preventDefault(), вызвать окно соц. сети
				if(dispatchEvent(new Event(errorEventType, false, true)))
					showPopup();
			}
		}// end refresh
		
		private function _onRefreshRequired(e:Event):void{
			removeEventListener(e.type, _onRefreshRequired);
			refresh();
		}
		
		
		/**
		 * Производит поиск заданных id в уже загруженных. При необходимости, обращается в соц. сеть за неизвестными
		 * @param uids массив id-шников
		 * @param onComplete в колбэк возвращается массив SocialUser-ов
		 * @param onError
		 */
		public function getProfiles(uids:Array, onComplete:Function, onError:Function = null):void{
			var i:int;
			
			// посмотреть в users
			var cache:Array = [];
			for(i = 0;i<uids.length;i++)
				if(users[uids[i]] != null && users[uids[i]].id == uids[i]){
					cache.push(users[uids[i]]);
					uids.splice(i, 1);
					i--;
				}
			
			if(uids.length){
				loadProfiles(uids, function(e:Array):void{
					var socialUsers:Array = [];
					for(var i:int;i<e.length;i++){
						socialUsers.push(createSocialUser(e[i]));
						addUser(socialUsers[socialUsers.length - 1]);
					}
					// соединить с cash и передать заинтересованной функции
					onComplete(socialUsers.concat(cache));
				}, onError);
			}else{
				// все пользователи получены из кэша
				onComplete(cache);
			}
		}// end getProfiles
		
		/**
		 * Добавить объект типа SocialUser во все хранилища пользовательских данных
		 * Внимание: не осуществляется проверка на повторное добавление, флаги inFriend, isAppFriend должны быть корректно выставлены
		 */
		public function addUser(user:SocialUser):void {
			users[user.id] = user;
			usersIds.push(user.id);
			if(user.isFriend){
				friends[user.id] = user;
				friendsIds.push(user.id);
			}
			if(user.isAppFriend){
				appFriends[user.id] = user;
				appFriendsIds.push(user.id);
			}
		}
		
		/**
		 * Возвратить пользователя по id
		 * @param id
		 */
		public function getUserById(id:String):SocialUser{
			if (users[id])
				return users[id];
			if(friends[id]);
				return friends[id];
			if(user_id == id)
				return user;
			return null;
		}
		public function getFriends():Array {return friends;}
		public function getAppFriends():Array {return appFriends;}
		public function getNotAppFriends():Array {
			var notAppFriends:Array = [];
			for(var s:String in friends)
				if(!SocialUser(friends[s]).isAppFriend)
					notAppFriends[s] = friends[s];
			return notAppFriends;
		}
		
		/**
		 * Проверяет, состоит ли пользователь в указанной группе
		 */
		public function isGroup(groupId:String):Boolean{
			if(!groups) return false;
			for(var i:int = 0;i<groups.length;i++)
				if(groups[i] == groupId)
					return true;
			return false;
		}
		
		
		/**
		 * Прочая индивидуальная информация
		 */
		public var location:String;// хранит #hash страницы
		protected var keys:*;// ключ для доступа к api
		public var flashVars:Object;
		
		/**
		 * Создать экземпляр SocialUser на основе информации от api
		 */
		public function createSocialUser(info:Object):SocialUser{
			throw new Error("Must be overridden");
		}
		
		/**
		 * Возвращает ключ для подписи запросов к игровому серверу, который (ключ) сгенерирован
		 * сервером соц. сети (берется как правило из flashVars)
		 */
		public function get authentication_key():String{
			throw new Error("Must be overridden");
		}
		
		public function get app_id():String
		{
			throw new Error("Must be overridden");
		}
		
		public function get user_id():String
		{
			throw new Error("Must be overridden");
		}
		
		
		/**
		 * Изменение размера приложения на лету
		 * @param width
		 * @param height
		 * @return 
		 * 
		 */		
		public function resizeApplication(width : int, height:int) : Boolean {
			return false;
		}
		
		
		/****************************************************************
		 * 
		 * Функции API, вызываемые в процессе выполнения
		 * 
		 ****************************************************************/
		
		/**
		 * Загружает профайлы запрошенных пользователей, обращаясь к api (в отличие от getProfiles, 
		 * которая сначала ищет профайлы среди ранее загруженных)
		 * В приложении используйте getProfiles для предварительного поиска среди уже загруженных профайлов
		 */
		public function loadProfiles(uids:Array, onComplete:Function, onError:Function = null):void{
			throw new Error("Must be overridden");
		}
		
		/**
		 * Загрузить профайл текущнего пользователя
		 * @param onComplete передается user:Object, например onComplete({first_name:"Павел", ... })
		 * 			ВНИМАНИЕ: хотя большинство соц. сетей возвращают информацию о текущем пользователе как array[0]:Object функция возвращает готовый user:Object
		 * 			например в функции onComplete(response:Object){
		 * 									// правильное обращение к свойству
		 * 									trace( response.first_name );
		 * 
		 * 									// неправильное обращение, которое вызовет ошибку
		 * 									trace( response[0].first_name );
		 * 								}
		 */
		public function loadUserProfile(onComplete:Function, onError:Function = null):void{
			throw new Error("Must be overridden");
		}
		
		public function loadUserGroups(onComplete:Function, onError:Function = null):void{
			throw new Error("Must be overridden");
		}
		/**
		 * Получить список id друзей пользователя
		 * @param onCompete передается friendsIds:Array, например onComplete(["234324", "2", "489210"])
		 */
		public function loadUserFriends(onComplete:Function, onError:Function = null):void{
			throw new Error("Must be overridden");
		}
		
		/**
		 * Получить список профайлов друзей пользователя. 
		 * РЕКОМЕНДУЕТСЯ вместо текущей функции пользоваться getProfiles, которая возвращает Array of SocialUser и кэширует запросы
		 * @param onComplete передается friends:Array of Objects, например onComplete([{first_name:"Друг 1", ...}, {...friend2...}, ...])
		 */
		public function loadUserFriendsProfiles(onComplete:Function, onError:Function = null):void{
			throw new Error("Must be overridden");
		}	
		
		/**
		 * Получить список id app-друзей пользователя
		 * @param onCompete передается friendsIds:Array, например onComplete(["234324", "2", "489210"])
		 */
		public function loadUserAppFriends(onComplete:Function, onError:Function = null):void{
			throw new Error("Must be overridden");
		}
		
		/**
		 * Получить игровой баланс пользователя (который уже сейчас доступен для снятия игровым сервером)
		 * @return реализован ли метод в конкретном api
		 */
		public function loadUserBalance(onComplete:Function, onError:Function = null):Boolean{
			return false;
		}
		
		/*****************************************************************
		 * 
		 * Функции JS/Flash оберток
		 * 
		 *****************************************************************/
		
		/**
		 * Показать окно установки приложеия (с необходимыми для игры настройками, если их можно запросить одновременно с установкой).
		 * Добавляет листенеры на изменение, листенеры обновляют свойства в flashVars
		 * @return Реализован ли метод в конкретном api
		 */
		public function showInstallBox(settings:* = null):Boolean{
			throw new Error("Must be overridden");
		}
		
		/**
		 * Показать окно выставления настроек для приложения. Добавляет листенеры на изменение
		 * @param settings требуемые настройки. Если не заданы, брать из PERMISSIONS
		 * Добавляет листенеры на изменение, листенеры обновляют свойства PERMISSIONS и в flashVars
		 * @return Реализован ли метод в конкретном api
		 */
		public function showSettingsBox(settings:* = null):Boolean{
			throw new Error("Must be overridden");
		}
		
		/**
		 * Показать окно оплаты
		 * @param socialMoney число денежных единиц, принятых в соц. сети, требуемых для оплаты
		 * @param onSuccess callback, когда пользователь положит требуемую сумму (или если она уже есть)
		 * @param title название покупки, например "Свинья 10-го уровня"
		 * @param message описание покупки, например "Свинья 10-го уровня обладает магическими способностями, которые пригодятся в бою"
		 * @param code текстовый идентификатор, отправляемый на сервер (сервером соц. сети), по которому игровой сервер определит, сколько денег внесено и какой товар был преобретен
		 * @param params дополнительные параметры реализации функций оплаты, индивидуальные для соц. сети (выясняется при реализации под конкретную специфичную сеть). Например, название игры и т.д.
		 * 			Пример:
		 * 			{
		 * 				other_price:23 // если сеть поддерживает оплату непосредственно реальными деньгами, а не игровой валютой (голосами, ОК-ами и прочими невалидными вещами), указать стоимость в прямой валюте
		 * 			}
		 * @return Реализован ли метод в конкретном api
		 */
		public function showPaymentBox(socialMoney:Number, onSuccess:Function = null ,title:String = null, message:String = null , code:String = null, params:Object = null):Boolean{
			throw new Error("Must be overridden");
		}
		
		
		/**
		 * Показать окно приглашения друзей
		 * @uid кого конкретно пригласить (да да, даже так можно на Facebook)
		 * @type как пригласить (например идентификатор фона странички-приглашалки)
		 * @return Реализован ли метод в конкретном api
		 */
		public function showInviteBox():Boolean{
			return false;
		}
		
		/**
		 * Осуществить постинг на стену заданного пользователя. Передаётся максимальное количество данных. 
		 * Конкретное исполнение SocialAdapter использует те поступившие данные, которые можно опубликовать в рамках api 
		 * @param recipient получатель сообщения (в зависимости от его типа: friend, appFriend..., 
		 * 			функция может озвращать различные значения). По умолчанию текущий пользователь
		 * @param title Заголовок
		 * @param message Текст собщения
		 * @param image Рисунок (DisplayObject, или Bitmap из которого берется bitmapData, или BitmapData)
		 * @param imageUrl путь до рисунка
		 * @param postData данные, связанные с постом (например, hash подарка)
		 * @param onComplete
		 * @param onError
		 * @param additionParams название игры и прочая вспомогательная информация, для осуществления грамотного постинга
		 * 			Пример:
		 * 			{
		 * 				name: "СуперскаяИгра", // название приложения
		 * 				playTo: "Играть в СуперскуюИгру",
		 * 				linkText: "Получить жестяную банку в подарок", // текст ссылки, переход по которой в приложение ознаменует получение подарка 	
		 * 				linkText: "Получить жестяную банку в подарок и кликнуть на ссылку", // (работает в мейл.ру - postData или additionParams["postData2"] как hash ссылки)
		 * 				permissionTitle: "Хотите разрешить приложению публиковать ваши достижения на стене?" // ленивые Одноклассники.ру этот текст сами придумать не могут			
		 * 			}
		 * @return Реализован ли метод в конкретном api
		 */
		public function wallPost(recipient:SocialUser = null, title:String = null, message:String = null, 
								 image:* = null,  imageUrl:String = null, postData:String = null,
								 onComplete:Function = null, onError:Function = null, additionParams:Object = null):Boolean{
			
			return (PERMISSION_WALL_FOR(recipient))	
		}
		/**
		 * получить записи на стене 
		 * @param onComplete
		 * @param onError
		 * 
		 */		
		public function wallGet(onComplete:Function = null, onError:Function = null) : void {
			throw new Error("Must be overridden");
		}
		
		/**
		 * загрузка фото на свою стену
		 */		
		public function wallPhotoPost(message:String='', photo:BitmapData=null, okCallback:Function=null, failCallback:Function=null, permissionGrantedCallback:Function=null) : Boolean {
			return PERMISSION_PHOTO;
		}
		
		/**
		 * запостить заметку 
		 */
		public function notePost(title: String, text : String=null, okCallback:Function=null, failCallback:Function=null) : void {
			//
		}
		/**
		 * запостить фотку в фотоальбом 
		 */		
		public function photoAlbumPost(albumTitle:String=null, albumDescription:String=null, 
									   image:* = null, onComplete:Function = null, 
									   onError:Function = null, rectangle:Rectangle=null) : Boolean {
			return PERMISSION_PHOTO;
		}
		
		
		
		/**
		 * Меняет статус пользователя
		 */
		public function setStatus(status:String, onComplete:Function, onError:Function, link:String = null, title:String = null):void
		{
			throw new Error("Must be overriden");
		}
		
		public function setBookmarkCounter(value:int=0, onSuccess:Function=null, onError:Function=null):void {
			throw new Error("Must be overriden");
		}
		
		/**
		 * Адрес текущего сайта
		 */
		public function get networkUrlAddress():String
		{
			throw new Error("Must be overriden");
		}
		
		//////////////////////////////////////////////////////////////////////////
		// 																		//
		//		Защищенные функции, общие для всех реализаций SocialAdapter		//
		// 																		//
		//////////////////////////////////////////////////////////////////////////
		
		// пользователь установил прилождение (прверка на основе flashVars)
		protected function _isAppUser():Boolean{
			throw new Error("Must be overridden");
		}
		// чтобы вызывать данную функцию из MegaBonusManager
		internal function __isAppUser():Boolean{			return _isAppUser();		}
		
		// пользователь разрешил необходимые нстройки (проверка на основе flashVars)
		protected function _checkPermission():Boolean{
			var highBit:int = int(Math.log(MANDATORY_PERMISSION_MASK)/Math.LN2);
			for(var i:int = 0; i <= highBit; i++)
				if(MANDATORY_PERMISSION_MASK & (1 << i))// если данный разряд requiredVkPermission имеет "1"
					if(!(PERMISSIONS & (1 << i)))
						return false;
			return true;
		}
		
		// произвести инициализационую загрузку, после которой вызвать onInitComplete (или onInitError в процессе ошибки)
		protected var _initData:Object = {"user":null,"friends":null,"appFriends":null};// хранилище загруженных данных, ждущих парсинга
		protected function _startInitLoading():void{
			loadUserProfile(function(e:Object):void{
				_initData["user"] = e;
				_checkInitLoadingCompletion();
			});
			loadUserFriendsProfiles(function(e:Object):void{
				_initData["friends"] = e;
				_checkInitLoadingCompletion();
			});
			loadUserAppFriends(function(e:Object):void{				
				_initData["appFriends"] = e;
				_checkInitLoadingCompletion();
			});
		}
		
		
		/**
		 * 
		 * @return были получены все необходимые данные для инициализации. В этом случае запускается _parceInitData();
		 * 
		 */
		protected function _checkInitLoadingCompletion():Boolean{
			if(_initData.user !== null && _initData.friends !== null && _initData.appFriends !== null){
				_parseInitData();
				return true;
			}
			return false;
		}
		
		// обработать данные, полученные на этапе инициализации от сервера соц. сети
		// предполагается, что _initData = {user:{ профиль },   appFriends:[  массив id app-друзей ]   ,    friends:[ массив профилей друзей  ]  }
		// после завершения парсинга, вызвать onInitComplete();
		protected function _parseInitData():void{
			var i:int;
			if(!(_initData.friends is Array)) _initData.friends = [];
			if(!(_initData.appFriends is Array)) _initData.appFriends = [];
			if(!(_initData.groups is Array)) _initData.groups = [];
			
			// перевести массив типа [1, 3, 6] в массив типа ["1", "3", "6"] - т.к. id юзеров  у нас сугубо String
			var tempAppFriendsIds:Array = _initData.appFriends;
			for(i = 0;i<tempAppFriendsIds.length;i++)
				tempAppFriendsIds[i] = String(tempAppFriendsIds[i]);
			
			for(i = 0;i<_initData.friends.length;i++){
				var friend:SocialUser = createSocialUser(_initData.friends[i]);
				var appFrienIndex:int = tempAppFriendsIds.indexOf(friend.id);
				if(appFrienIndex != -1)
				{
					friend.isAppFriend = true;
					tempAppFriendsIds.splice(appFrienIndex, 1);
				}
				friend.isFriend = true;
				addUser(friend);
			}
			user = createSocialUser(_initData.user);
			user.itsMe = true;
			users[user.id] = user;
			usersIds.push(user);
			
			if(_initData.groups)
				groups = _initData.groups;
			
			if(tempAppFriendsIds.length)
			{
				// послать еще запрос
				loadProfiles(tempAppFriendsIds, function(resp:Object):void{
					var missing:Array = resp as Array;
					if(missing == null) missing = [];
					for(var j:int = 0;j<missing.length;j++)
					{
						var s:SocialUser = createSocialUser(missing[j]);
						s.isAppFriend = true;
						s.isFriend = true;
						addUser(s);
					}
					complete();
				}, function(error:Object):void{
					// загружаемся без части апп юзеров
					complete();
				});
			}else
			{
				complete();
			}
			function complete():void
			{
				initState = 4;
				dispatchEvent(new Event(SocialAdapter.EVENT_INITED));
				onInitComplete && onInitComplete();
			}
		}
		
		/**
		 * Возвращает адрес api для конкретной соц. сети
		 * @param request возможность задавать путь до url в соответствии с параметрами запроса
		 */
		protected function _getApiUrl(method:String, request:Object = null):String{
			throw new Error("Must be overridden");
		}
		
		/**
		 * Послать запрос на сервер, с заданными полями 
		 * @param method
		 * @param options перечисленные переменные:значения, отправляемые на сервер
		 * 					Могут содержать следующие параметры, не посылаемые на сервер, но управляющие параметрами отсылки данных
		 * 					url полный путь до api
		 * @param onComplete функция по успешному получению ответа от сервера onComplete(response:Object)
		 * @param onError функция по ошибочному обмену данными с сервером onError({error:String [, error_code:int] ...})
		 * @param GET метод передачи данных (GET/POST)
		 * 
		 */
		protected function _sendRequest(method:String, request:Object = null, onComplete:Function = null, onError:Function = null, GET:Boolean = false):void {     		
			
			var urlRequest:URLRequest = new URLRequest();
			urlRequest.method = GET?URLRequestMethod.GET:URLRequestMethod.POST;
			urlRequest.url = _getApiUrl(method, request);
			
			var urlVariables:URLVariables = _getUrlVariables(method);
			
			if(request){
				for(var s:String in request)
					urlVariables[s] = request[s];
			}
			
			_createSignature(urlVariables);
			
			var urlLoader:URLLoader = new URLLoader();
			urlLoader.addEventListener(Event.COMPLETE, onLoaderComplete);
			urlLoader.addEventListener(IOErrorEvent.IO_ERROR, onIOError);
			urlLoader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, onSecurityError);
			
			urlRequest.data = urlVariables;
			
			urlLoader.load(urlRequest);			
			
			function onLoaderComplete(e:Event):void{
				clearLoader(e.target);
				// передать данные от сервера отдельной функции-обработчику
				_responseHandler(e.target.data, onComplete, onError);
			}
			
			function onIOError(e:IOErrorEvent):void{
				clearLoader(e.target);
				onError && onError({error:e.text});
			}
			
			function onSecurityError(e:SecurityErrorEvent):void{
				clearLoader(e.target);
				onError && onError({error:e.text});
			}
			// очистка от всех листенеров
			function clearLoader(loader:URLLoader):void{
				loader.removeEventListener(Event.COMPLETE, onLoaderComplete);
				loader.removeEventListener(IOErrorEvent.IO_ERROR, onIOError);
				loader.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, onSecurityError);
			}
		}
		
		
		/**
		 * Возвращает объект для серверного запроса, с предустановленными значениями, 
		 * общими для всех запросов (типа uid, auth_key...)
		 * @param method название метода api
		 */
		protected function _getUrlVariables(method:String):URLVariables{
			throw new Error("Must be overridden");
		}
				
		/**
		 * Создать подпись запроса (если в этом есть необходимость для текущей соц. сети)
		 */
		protected function _createSignature(urlVariables:Object):void{
			
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
		protected function _responseHandler(response:String, onComplete:Function, onError:Function):Boolean{
			if(response == null || response == ""){
				onError && onError({error:"Empty server response"});
				return false;
			}else{
				// если озвращает true, данные от сервера возможно нужно конвертировать (например JSON)
				// и подвергнуть дополнительной обработке на ошибки. После этого передать в onComplete
				return true;
			}
		}
		
		/**
		 * Осуществляет декодирование JSON
		 * При ошибке декодирования вызывется onError, иначе возвращается декодированный объект
		 * Применяется в оверрайдах _responseHandler, когла соц. сеть возвращает ответ в виде JSON.
		 * Чтобы обработка типичных ошибок декодинга происходила аналогично
		 */
		protected function _safetyJSONDecode(response:String, onError:Function):Object{
			try{
				var responseData:Object = JSON.decode(response);
				if(responseData == null || responseData === "" || responseData === "null")
					onError && onError({error:"JSON parsing error (empty result)"});
				else
					return responseData;	
			}catch(e:Error){
				onError && onError({error:"JSON parsing error"});				
			}
			return null;// возвращает в случае ошибки парсинга
		}
	}
}
