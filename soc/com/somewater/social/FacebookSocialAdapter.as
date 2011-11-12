package com.somewater.social
{
	import com.adobe.crypto.MD5;
	import com.adobe.serialization.json.JSON;
	import flash.events.Event;
	import flash.external.ExternalInterface;
	import flash.net.URLVariables;
	import flash.utils.Dictionary;
	
	/**
	 * Реализует работу с соц. сетью Facebook аналогично методам базового класса SocialAdapter
	 * Работает с сервером соц. сети на основе технологии Graph API (c) Facebook (если выставить USE_GRAPH = true)
	 */
	public class FacebookSocialAdapter extends SocialAdapter
	{
		internal const PERMISSION_EMAIL_MASK:int = 4;// сервер приложения может слать нотифаи на email игрока
		public function get PERMISSION_EMAIL():Boolean {return Boolean(PERMISSIONS & PERMISSION_EMAIL_MASK);}
		
		private const USE_GRAPH:Boolean = false;// работа с graph api не реализована!!!
		private const GRAPH_API:String = "https://graph.facebook.com/";
		//private const REST_API:String = "http://api.facebook.com/restserver.php";// старый добрый REST_API
		private const REST_API:String = "https://api.facebook.com/method/";// новый злой REST_API c SSL
		
		
		/**
		 * Функции-получатели данных из flashVars (т.к. принцип построения flashVars 
		 * может поменяться с переходом на авторизацию OAuth 2.0)
		 */
		private function get uid():String{	return flashVars["uid"]?flashVars["uid"]:flashVars["session"]["uid"];		}
		//private function get secret():String{	return flashVars["session"]["secret"];		}
		private function get session_key():String{	return flashVars["session_key"]?flashVars["session_key"]:flashVars["session"]["session_key"];		}
		protected function get access_token():String{	return flashVars["access_token"]?flashVars["access_token"]:flashVars["session"]["access_token"];		}
		public function get application_path():String { return flashVars["app_path"]; }
		override public function get app_id():String{ return flashVars["app_id"]?flashVars["app_id"]:(access_token.substring(0,access_token.indexOf("|"))); }
		public function get like():Boolean{return (_initData.groups && _initData.groups[0] && _initData.groups[0]["page_id"] && (_initData.groups[0]["page_id"] == app_id))}// либит ли пользователь приложение
		
		protected var stringPerms:String;// настройки в виде строки "param1,param2,param3"
			
		
		
		
		public function FacebookSocialAdapter()
		{
			CAN_RESIZE = true;
			
			PERMISSIONS = 1;// помеченные "1" нижеследующие функции работают всегда (без необходимости выставлять настройки)
			
			PERMISSION_NOTIFICATION_MASK = 1;
			PERMISSION_FRIENDS_MASK = 1;// всегда работает	
			PERMISSION_WALL_USER_MASK = PERMISSION_WALL_FRIEND_MASK = PERMISSION_WALL_APPFRIEND_MASK = 2;// одновременно включаются
			PERMISSION_BOOKMARK_MASK = 8;// если приложение было запущено, значит оно добавлено в bookmark. Проверить факт удаления из bookmark нельзя
			
			//  PERMISSION=4 занята под "email" !!!
			super();
			
			DEFAULT_PERMISSION_MASK = PERMISSION_WALL_FRIEND_MASK;
		}
		
		
		override public function get networkUrlAddress():String
		{
			return "http://facebook.com";
		}
		
		override protected function preRefresh():void{
			//parcePermissions(); - можно раскомментить, когда север станет присылать permissions			
			if(flashVars["session"] is String){
				flashVars["session"] = JSON.decode(flashVars["session"]);
				if(USE_GRAPH)
					keys = flashVars["session"]["access_token"]; // если используется авторизация по Token
			}
 			if(!location && flashVars["pstar_loc"]){
				location = flashVars["pstar_loc"];
				trace("*******\n	loc=" + location + "\n*******");
				dispatchEvent(new Event(SocialAdapter.EVENT_LOCATION_CHANGED));
			}
			if(ExternalInterface.available){
				ExternalInterface.addCallback("flashCallback", flashCallback);
				flashCallbacks["permissionChanged"] = function(perms:String):void{
															stringPerms = perms; 
															parcePermissions(); 
															dispatchEvent(new Event(SocialAdapter.EVENT_PERMISSION_CHANGED))
														}
			}
		}		
		
		/**
		 * Обеспечивает работу с callback-s из js так, будто они происходят непосредственно из флешки
		 */
		protected var flashCallbacks:Dictionary = new Dictionary(true);
		public function flashCallback(...args):void{
			trace("flashCallback:" + JSON.encode(args));
			if(args.length > 0 && flashCallbacks[args[0]]){
				flashCallbacks[args[0]].apply(this, 
					args.slice(1));
			}	
		}
		
		override public function refresh(...args):void{			
			// проверки на installApp, Permissions не производятся (приложение устанавливается и получает настройки до запуска)
			if(initState < 3){
				initState = 3;
				_startInitLoading();
			}
		}
		
		override protected function _startInitLoading():void{
			//super._startInitLoading();
			
			/*setTimeout(function():void{
				// получить permissions
				_sendRequest("fql.query", {"query":"SELECT publish_stream,user_birthday FROM permissions WHERE uid = me()"}, function(response:Object):void{
					var perms:Array = [];
					for(var s:String in response[0])
						if(response[0][s] == 1)
							perms.push(s);
					stringPerms = perms.toString();
					parcePermissions();
					_checkInitLoadingCompletion();
				});
			},100);*/
			
			var user:String = '"SELECT uid,first_name,last_name,pic_small,pic,pic_big,birthday_date,sex,locale,profile_url FROM user WHERE uid = me()"';
			var friends:String = '"SELECT uid,first_name,last_name,sex,pic_small,pic,is_app_user FROM user WHERE uid IN (SELECT uid2 FROM friend WHERE uid1 = me())"';
			var groups:String = '"SELECT page_id FROM page_fan WHERE  uid=me() AND page_id=' + app_id + '"';
			var perms:String = '"SELECT publish_stream,user_birthday,email,bookmarked FROM permissions WHERE uid = me()"';
			
			var queries:String = '{"user":' + user + ',"friends":' + friends + ',"groups":' + groups + ',"perms":' + perms + '}';
			
			_sendRequest("fql.multiquery", {"queries":queries}, 
				function(e:Object):void{
					// multiquery complete
					_initData["friends"] = tag(e, "friends");
					if(!(_initData["friends"] is Array)) _initData["friends"] = [];
					_initData["user"] = tag(e, "user")[0];
					_initData["groups"] = tag(e, "groups");
					_initData["appFriends"] = [];
					for(var i:int = 0;i<_initData["friends"].length;i++)
						if(_initData["friends"][i]["is_app_user"])
							_initData["appFriends"].push(_initData["friends"][i]["uid"]);
					var perms:Array = [];
					var permsObj:Object = tag(e, "perms")[0];
					for(var s:String in permsObj)
						if(permsObj[s] == 1)
							perms.push(s);
					stringPerms = perms.toString();
					parcePermissions();
					_parseInitData();
					
				}, 
				function(e:Object):void{
					// multiquery error
					onInitError && onInitError();
				});
				
			function tag(array:Array, name:String):Object{
				for(var i:int = 0;i<array.length;i++)
					if(array[i]["name"] == name)
						return array[i]["fql_result_set"];
				return null;
			}
		}
		
		// применяется только в том случае, если init производится не multiquery запросом
		override protected function _checkInitLoadingCompletion():Boolean{
			if(_initData.user && _initData.friends && _initData.appFriends && stringPerms != null){
				_parseInitData();
				return true;
			}
			return false;
		}
		
		override public function get authentication_key():String{
			return "auth_key";
		}
		
		override public function createSocialUser(info:Object):SocialUser{
			var socialUser:SocialUser = new SocialUser();
			socialUser.id = info["uid"];
			socialUser.locale = info['locale'];
			if(socialUser.locale is String) {
				socialUser.locale = socialUser.locale.substr(0,2);//cut the _RU part in ru_RU
			}
			socialUser.firstName = info["first_name"];
			socialUser.lastName = info["last_name"];
			socialUser.male = !(info["sex"] == "female");
			if( !info["pic"]) info["pic"] = info["pic_square"];
			if( !info["pic"]) info["pic"] = info["pic_small"];
			if( !info["pic_small"]) info["pic_small"] = info["pic"];
			if( !info["pic_big"] ) info["pic_big"] = info["pic"];
			socialUser.photos = [info["pic_small"],info["pic"],info["pic_big"]];
			return socialUser;
		}
		
		/**
		 * Показать окно с кнопкой "like" (или unlike)
		 * @param onlyLike не вызывать окно, если пользователь уже нажал "like" (не дать возможность нажать unlike)
		 * @return было ли вызвано окно
		 */
		public function showLike(onlyLike:Boolean = false):Boolean{
			if(ExternalInterface.available){
				if(!onlyLike || !like)
					ExternalInterface.call("inviteFriends", "like.php");
				return true;
			}else
				return false;
		}
		
		/**
		 * Скрыть таб "LIKE" над флешкой
		 * return удалось ли скрыть таб
		 */
		public function hideLikeButton():Boolean{
			return false;
		}
		
		override public function loadProfiles(uids:Array, onComplete:Function, onError:Function=null):void{
			if(uids.length)
				_sendRequest("users.getInfo", {"uids": uids.join(), "fields": "uid,first_name,last_name,sex,pic_small,pic"}, 
						function(users:Object):void{
								if(!(users is Array)) users = [];
								onComplete(users);
						}, onError);
			else
				onComplete && onComplete([]);
		}
		
		override public function loadUserProfile(onComplete:Function, onError:Function=null):void{
			_sendRequest("users.getInfo", {"uids": uid, "fields": "locale,uid,first_name,middle_name,last_name,sex,pic_small,pic,pic_big,profile_url"}, 
				function(user:Object):void{
					onComplete(user[0]);
			}, onError);
		}
		
		
		override public function loadUserFriends(onComplete:Function, onError:Function=null):void{
			_sendRequest("friends.get", null, function(friendsIds:Object):void{
				if(!(friendsIds is Array)) friendsIds = [];
				onComplete(friendsIds);
			}, onError);
		}
		
		override public function loadUserFriendsProfiles(onComplete:Function, onError:Function=null):void{
			loadUserFriends(function(friendsIds:Array):void{
				loadProfiles(friendsIds, onComplete, onError);
			}, onError);			
		}
		
		override public function loadUserAppFriends(onComplete:Function, onError:Function=null):void{
			_sendRequest("friends.getAppUsers", null, function(appIds:Object):void{
				if(!(appIds is Array)) appIds = [];
				onComplete(appIds);
			}, onError);
		}
		
		override public function showInviteBox():Boolean{
			if(ExternalInterface.available){
				var vars:String = "exclude_ids=" + appFriendsIds.join() + "&uid=" + user.id;
				vars += (uid?"&uid=" + uid:"");
				
				// поставили новые коллбэки или затерли старые
				/*
				if(onComplete)
					flashCallbacks["inviteActionComplete"] = onComplete;
				else
					flashCallbacks["inviteActionComplete"] = null;				
				if(onError)
					flashCallbacks["inviteActionError"] = onError;
				else
					flashCallbacks["inviteActionError"] = null;
				*/
				ExternalInterface.call("inviteFriends");
				return true;
			}else
				return false;
		}
		
		/**
		 * Перевести числовое представление настроек в принятое на facebook
		 * @param permissions
		 * @param assArray возвратить массив ["perm1", "perm2"] или стринг "perm1,perm2"
		 */
		protected function getStringPermissions(permissions:uint, asArray:Boolean):*{
			var permissionsArray:Array = [];
			if(PERMISSION_WALL_USER_MASK & permissions) permissionsArray.push("publish_stream");
			if(PERMISSION_EMAIL_MASK & permissions) permissionsArray.push("email");
			if(PERMISSION_BOOKMARK_MASK & permissions) permissionsArray.push("bookmarked");

			if(asArray)
				return permissionsArray;
			else
				return permissionsArray.join();
		}
		
		override public function showSettingsBox(settings:*=null):Boolean{
			if(ExternalInterface.available){
				
				// hook из за глючности facebook, которые отдают недокументированный пар-р bookmarked, но не поддерживают его установку
				if(settings & PERMISSION_BOOKMARK_MASK){
					flashCallbacks["permissionChanged_bookmarks"] = function(response:*):void{
						if(response) PERMISSIONS = PERMISSIONS | PERMISSION_BOOKMARK_MASK;
						dispatchEvent(new Event(SocialAdapter.EVENT_PERMISSION_CHANGED));
					}
					ExternalInterface.call("addBookmarks");
					return true;
				}
				
				ExternalInterface.call("setPerms", getStringPermissions(settings?settings:MANDATORY_PERMISSION_MASK, false));
				return true;
			}
			return false;
		}
		
		override public function showPaymentBox(socialMoney:Number, onSuccess:Function=null, 
				title:String=null, message:String=null, code:String=null, params:Object=null):Boolean{
			if(ExternalInterface.available){
				
				if(code)
					ExternalInterface.call("payment", code);
				else
					ExternalInterface.call("payment", socialMoney);
				
				
				flashCallbacks["payment"] = null;
				flashCallbacks["payment"] = function(paymentStatus:String):void{
					if(paymentStatus == "settled")
						onSuccess && onSuccess();
				}
				return true;
				return false;
			}
			return false;
		}
		
		
		override public function resizeApplication(width:int, height:int):Boolean{
			if(CAN_RESIZE && ExternalInterface.available){
				ExternalInterface.call("resizeFlash", width, height);
				return true;
			}else
				return false;
		}
		
		
		/** картинки для stream.publish */		
		public var images:Dictionary = new Dictionary();
		
		
		override public function wallPost(recipient:SocialUser=null, title:String=null, message:String=null, image:*=null, 
										  imageUrl:String=null, postData:String=null, onComplete:Function=null, onError:Function=null, additionParams:Object=null):Boolean{
			
			trace("images " + images[imageUrl], imageUrl);
			if(images[imageUrl]) {
				imageUrl = images[imageUrl];
				if(additionParams && additionParams.imagePostfix) {
					var ind : int = imageUrl.lastIndexOf('.');
					if(ind != -1) {
						imageUrl = imageUrl.substr(0,ind)+additionParams.imagePostfix+imageUrl.substr(ind);
					}
					delete additionParams.imagePostfix;
				}
			}
			else
				trace("No image in images dictionary for " + imageUrl);
			
			
			if(recipient == null)
				recipient = user;
			
			
			
			if(true || super.wallPost(recipient)){// hook постить можно всегда (при условии выставления настройки)
				if(!PERMISSION_WALL_FOR(recipient)){
					// hook, позволяющий продолжить постинг после успешного выставления настроек
					onWallStreamPermission(arguments);
					return true;
				}
				
				// запостить		
				var href:String = application_path + "?pstar_loc=" + postData + "&oid=" + user.id + "&vid=" + recipient.id;	
				
				if(!additionParams)	additionParams = {};
				if(!additionParams["linkText"] && additionParams["playTo"])
					additionParams["linkText"] = additionParams["playTo"];
				if(!additionParams["linkText"] && additionParams["name"])
					additionParams["linkText"] = additionParams["name"];
				if(!additionParams["linkText"])
					additionParams["linkText"] = "Play the game";
				
				var data:Object = {	//"message": message,  // - сообщение в самом верху, рядом с именем постера
					"target_id": recipient.id
				}
				if(recipient.itsMe)
					data["privacy"] = '{"value":"ALL_FRIENDS"}';
				
				
				var attachment:Object = {
					"name": title,
					//"description": message,  // дуюлирует "caption", но пишется около него
					"caption": message,
					"href": href,
					"media" :[{
						"type": "image",
						"src": imageUrl,
						"href": href
					}]													
				};
				if(additionParams["message2"])
				{
					attachment["description"] = additionParams["message2"];
					attachment["message"] = additionParams["message2"];
				}
				
				data["attachment"] = JSON.encode(attachment);
				data["action_links"] = JSON.encode([{"text":additionParams["linkText"], "href": href}]);
				
				_sendRequest("stream.publish", data, 
					function(complete:Object):void{
						// on complete
						if(/^[0-9]*_[0-9]*$/g.test(String(complete))){
							ExternalInterface.available && ExternalInterface.call("showAlert", "Message sent");
							onComplete && onComplete(complete);
						}else{
							// всё таки произошла какая-то ошибка
							trace("Error response:" + complete);
							ExternalInterface.available && ExternalInterface.call("showAlert", "Message was not sent");
							onError && onError(complete);
						}								
					}, 
					function(error:Object):void{
						// on error
						ExternalInterface.available && ExternalInterface.call("showAlert", "Message was not sent");
						onError && onError(error);
					});
				return true;
			}
			return false;
		}
		

		//Когда пользователь пытается постить на свою стену, не выставив натсройку "stream"		 
		//Функция пытается выставить настройку и, если будет выставлена, запостить как "stream"
		protected var lastWallStreamPermArgs:*;// хранит аргументы, переданные последней вызванной функции onWallStreamPermission
		protected function onWallStreamPermission(args:Array):void{
			lastWallStreamPermArgs = args;
			removeEventListener(SocialAdapter.EVENT_PERMISSION_CHANGED, onWallStreamPermissionSuccess);
			addEventListener(SocialAdapter.EVENT_PERMISSION_CHANGED, onWallStreamPermissionSuccess);
			showSettingsBox(PERMISSION_WALL_USER_MASK);
		}
		// callback на изменение настроек приложения
		protected function onWallStreamPermissionSuccess(e:Event):void{
			if(lastWallStreamPermArgs[0]?PERMISSION_WALL_FOR(lastWallStreamPermArgs[0]):PERMISSION_WALL_USER)
				wallPost.apply(this, lastWallStreamPermArgs);
		}
		
		
		
		override public function setStatus(status:String, onComplete:Function, onError:Function, link:String=null, title:String=null):void
		{
			if(!PERMISSION_WALL_FOR(user)){
				// hook, позволяющий продолжить постинг после успешного выставления настроек
				onStausStreamPermission(arguments);
				return;
			}
			_sendRequest("status.set", {"uid": user.id, "status": status}, onComplete, onError);
		}
		
		
		//Когда пользователь пытается менять статус, не выставив натсройку "stream"		 
		//Функция пытается выставить настройку и, если будет выставлена, запостить как "stream"
		private var lastStatusStreamPermArgs:*;// хранит аргументы, переданные последней вызванной функции onWallStreamPermission
		private function onStausStreamPermission(args:Array):void{
			lastStatusStreamPermArgs = args;
			removeEventListener(SocialAdapter.EVENT_PERMISSION_CHANGED, onStatusStreamPermissionSuccess);
			addEventListener(SocialAdapter.EVENT_PERMISSION_CHANGED, onStatusStreamPermissionSuccess);
			showSettingsBox(PERMISSION_WALL_USER_MASK);
		}
		// callback на изменение настроек приложения
		private function onStatusStreamPermissionSuccess(e:Event):void{
			if(PERMISSION_WALL_USER)
				setStatus.apply(this, lastStatusStreamPermArgs);
		}

		/**
		 * Отправить сообщение на email пользователя(лей)
		 * @param recipient SocialUser, которому отправляется сообщение (если null то отправляется текущему юзеру). У получателя должна быть выставлен пермишн email
		 *        (например, если я выставил пермишн и шлю другу, который пермишн не выставил, сообщение не дойдет)
		 * @param text
		 * @param subject
		 * @param onComplete
		 * @param onError
		 * 
		 * Внимание: api поддерживает постинг сразу 100 человек, однако если хотя бы 1 из них не выставил настройки, сообщения не отправляются НИКОМУ
		 * Поэтому функция сделана для посылки единичного сообщения
		 * 
		 */
		public function sendEmail(recipient:SocialUser, text:String, subject:String, onComplete:Function, onError:Function):void{
//			if(recipients == null || recipients.every(function (element:*, index:int, arr:Array):Boolean{return !(element is SocialUser)}))
//				throw new Error("resipients must be array of SocialUser");
			if(PERMISSION_EMAIL)
			{
//				var ids:String = "";
//				for(var i:int = 0;i<recipients.length;i++)
//					ids += SocialUser(recipients[i]).id + (i < (recipients.length - 1)?",":"");
				if(recipient == null) recipient = user;
				_sendRequest("notifications.sendEmail", {"recipients":recipient.id, "subject":subject, "text":text}, onComplete, onError);
			}else{
				onEmailPermission(arguments);
			}
		}
		
		//Когда пользователь пытается менять статус, не выставив натсройку "stream"		 
		//Функция пытается выставить настройку и, если будет выставлена, запостить как "stream"
		private var lastSendEmailStreamPermArgs:*;// хранит аргументы, переданные последней вызванной функции onWallStreamPermission
		private function onEmailPermission(args:Array):void{
			lastSendEmailStreamPermArgs = args;
			removeEventListener(SocialAdapter.EVENT_PERMISSION_CHANGED, onEmailPermissionSuccess);
			addEventListener(SocialAdapter.EVENT_PERMISSION_CHANGED, onEmailPermissionSuccess);
			showSettingsBox(PERMISSION_EMAIL_MASK);
		}
		// callback на изменение настроек приложения
		private function onEmailPermissionSuccess(e:Event):void{
			if(PERMISSION_EMAIL)
				sendEmail.apply(this, lastSendEmailStreamPermArgs);
		}
		
		
		override protected function _isAppUser():Boolean{
			return true;// если флешка имела честь быть запущеной, значит приложение уже добавлено на страницу
		}
		
		protected function parcePermissions():void{
			PERMISSIONS = 1;// настройки с индексом "1" по умолчанию работают, безо всяких настек
			if(stringPerms.indexOf("publish_stream") != -1)
				PERMISSIONS |= PERMISSION_WALL_USER_MASK;
			if(stringPerms.indexOf("email") != -1)
				PERMISSIONS |= PERMISSION_EMAIL_MASK;
			if(stringPerms.indexOf("bookmarked") != -1)
				PERMISSIONS |= PERMISSION_BOOKMARK_MASK;
		}
		
		
		
		//////////////////////////////////////////////////////
		//												  	//		
		//		Функции - получатели данных из flashVars	//
		//													//
		//////////////////////////////////////////////////////
		

		
		override protected function _getApiUrl(method:String, request:Object=null):String{
			return REST_API+method;
			//return REST_API;// + "" + "?access_token=" + access_token + "&";
		}
        
        override protected function _getUrlVariables(method:String):URLVariables{
        	var urlVariables:URLVariables = new URLVariables();
        	urlVariables["format"] = "JSON";
        	urlVariables["method"] = method;
        	urlVariables["v"] = "1.0";
        	urlVariables["api_key"] = keys;
        	urlVariables["session_key"] = session_key;
        	urlVariables["ss"] = "1";// неизвестно что это такое, доки по столь старой реализации api уже отсутствуют, но наши коллеги из PlatFish отправляют и не жалуются
        	return urlVariables;
        }
        
        /**
         * Переписываем, чтобы параметр GET по умолчанию (и в любых случаях) был true 
         * ? на этапе разработки следить, чтобы пользователь задавал его в ручную ?
         */
        override protected function _sendRequest(method:String, request:Object=null, onComplete:Function=null, onError:Function=null, GET:Boolean=false):void{
			super._sendRequest(method, request, onComplete, onError);	
		}
		
		override protected function _createSignature(urlVariables:Object):void{
			urlVariables['access_token'] = access_token;
			return;
			/*
			var sig : String = '';
			var keys : Array = [], key : String;
			for (key in urlVariables) { keys.push(key);}
			keys.sort();
			var i: int = 0, l : int = keys.length;
			for (i; i < l; i++)
			{
				sig += keys[i] + "=" + urlVariables[keys[i]];
			}
			sig += secret;
			urlVariables["sig"] = MD5new.encrypt(sig).toLowerCase();*/
		} 
        
		override protected function _responseHandler(response:String, onComplete:Function, onError:Function):Boolean{
			if(super._responseHandler(response, onComplete, onError)){
				var serverResponce:Object = _safetyJSONDecode(response, onError);
				if(serverResponce){
					if(serverResponce.hasOwnProperty("error_code")){
						
						switch(serverResponce.error_code)
						{
							case 190:// Invalid OAuth 2.0 Access Token
								dispatchEvent(new Event(EVENT_AUTHORIZATION_ERROR));
								break;
						}
						
						onError && onError(serverResponce);
					}else{
						onComplete && onComplete(serverResponce);
						return true;
					}
				}else{
				}
			}
			return false;
		}	
	}
}
