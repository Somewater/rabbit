/*************
 *
 *	Когда нибудь будет использован
 *
 *************/
package com.somewater.social
{
	import com.adobe.crypto.MD5;
	import com.adobe.serialization.json.JSON;
	
	import flash.events.Event;
	import flash.net.URLVariables;
	import flash.utils.Dictionary;
	
	public class OdnoklassnikiSocialAdapter extends SocialAdapter
	{
		public var APP_URL:String = "";// путь до приложения
		
		/**
		 * В init(..., secret_keys:*) не требуется задавать ключи (берутся из flashVars). Можно задать null
		 */
		public function OdnoklassnikiSocialAdapter()
		{
			PERMISSIONS = 1;// помеченные "1" нижеследующие функции работают всегда (без необходимости выставлять настройки)
			
			//PERMISSIONS += 2 + 4 + 8 + 16;// т.к. непонятно как выставлять настройки
			
			PERMISSION_NOTIFICATION_MASK = 0;
			PERMISSION_FRIENDS_MASK = 1;// всегда работает	
			PERMISSION_WALL_USER_MASK = 2;//
			PERMISSION_WALL_FRIEND_MASK = PERMISSION_WALL_APPFRIEND_MASK = 0;// т.е. работают одновременно (или одновремено не работают)
			PERMISSION_PHOTO_MASK = 8;
			PERMISSION_STATUS_MASK = 16;
			
			super();
			
			DEFAULT_PERMISSION_MASK = PERMISSION_WALL_USER_MASK;
			MANDATORY_PERMISSION_MASK = 0;// ничего не требуется для запуска
		}
		
		
		override public function get networkUrlAddress():String
		{
			return "http://odnoklassniki.ru";
		}
		
		
		override public function init(flashVarsHolder:Object, onComplete:Function, onError:Function=null, secret_keys:*=null):void{
			var lastAutoRefresh:Boolean = autoRefresh;
			autoRefresh = false;// super.init(...) лишь выставляет данные, не запуская взаимодействия с соц. сетью
			super.init(flashVarsHolder, onComplete, onError);
			keys = flashVars["session_secret_key"];
			
			if(flashVars["custom_args"] != null){
				location = flashVars["custom_args"];
				dispatchEvent(new Event(SocialAdapter.EVENT_LOCATION_CHANGED));
			}
			
			autoRefresh = lastAutoRefresh;
			if(autoRefresh)
				refresh();
		}
		
		override public function refresh(...args):void{			
			// проверки на installApp, Permissions не производятся (приложение устанавливается и получает настройки до запуска)
			if(initState < 3 && ForticomAPI.connected){
				initState = 3;
				_startInitLoading();				
			}
		}
		
		override protected function preRefresh():void{
			ForticomAPI;
			if(!ForticomAPI.connected){
				ForticomAPI.addEventListener(ForticomAPI.CONNECTED, ForticomAPI_connected);
				ForticomAPI.addEventListener(ForticomAPI.CALL_BACK, function(e:Event):void{trace("******\n" + "FAPI callback: " + e.toString() + "\n******")});
				ForticomAPI.addEventListener(ForticomAPI.SEND_ERROR, ForticomAPI_connectError);
				ForticomAPI.connection = flashVars["apiconnection"];
			}
		}
		
		
		
		protected function ForticomAPI_connected(e:Object = null):void{
			ForticomAPI.removeEventListener(ForticomAPI.CONNECTED, ForticomAPI_connected);
			ForticomAPI.removeEventListener(ForticomAPI.SEND_ERROR, ForticomAPI_connectError);
			refresh();
		}
		
		protected function ForticomAPI_connectError(e:Object = null):void{
			onInitError && onInitError();
		}
		
		override protected function _startInitLoading():void{
			super._startInitLoading();
			// не ждем завершения функции получения permission, т.к. она будет нужна гораздо позже и успеет отработать
			_sendRequest("users.hasAppPermission", {"ext_perm":"PUBLISH TO STREAM"},function(response:Object):void{
				if(response){
					PERMISSIONS |= PERMISSION_WALL_USER_MASK;
				}
			});
		}
		
		override public function createSocialUser(info:Object):SocialUser{
			var socialUser:SocialUser = new SocialUser();
			socialUser.id = info["uid"];
			socialUser.firstName = info["first_name"];
			socialUser.lastName = info["last_name"];
			socialUser.male = !(info["gender"] == "female");
			if( !info["pic_2"] ) info["pic_2"] = info["pic_1"];
			if( !info["pic_3"] ) info["pic_3"] = info["pic_2"];
			socialUser.photos = [info["pic_1"], info["pic_2"], info["pic_3"]];
			if(info["birthday"]){
				var a:Array = info["birthday"].split("-");
				// TODO: обрабатывать неполную дату рождения. Знать бы как она приходит
				var d:Date = new Date(Number(a[0]), Number(a[1]) - 1, Number(a[2]));
				socialUser.bdate = d.time * 0.001;
			}
			return socialUser;
		}
		
		/**
		 * Проверка на сервере следующим образом:
		 * authentication_key == md5(flashVars + Secret_Key);
		 * 	где flashVars:String получена ранее от объекта initObject.flashVars
		 * 		Secret_Key в настройках приложения (флешке не передается)
		 */
		override public function get authentication_key():String{
			return flashVars["auth_sig"] + '_' + flashVars["session_key"];
		}
		
		/**
		 * Обеспечивает получение любого числа uid, несмотря на то, что api odnoklassniki не выдает более 100
		 * (получение серией запросов)
		 */
		override public function loadProfiles(uids:Array, onComplete:Function, onError:Function=null):void{
			// полученные профили
			var received:Array = [];
			
			if(uids.length)
				getNext100Profiles();
			else
				onComplete && onComplete([]);
			
			function getNext100Profiles():void{
				_sendRequest("users.getInfo", {"uids": (uids.splice(0, Math.min(uids.length, 100)) as Array).join(), "fields": "uid,first_name,last_name,gender,pic_1,pic_2"}, onInnerComplete, onError);
			}
			
			function onInnerComplete(profiles:Array):void{
				received = received.concat(profiles);
				
				if(uids.length){
					getNext100Profiles();
				}else{
					onComplete(received);
				}
			}			
		}
		
		override public function loadUserProfile(onComplete:Function, onError:Function=null):void{
			_sendRequest("users.getInfo", {"uids": flashVars["logged_user_id"], "fields": "uid,first_name,last_name,gender,pic_1,pic_2,pic_3,birthday"}, innerOnComplete, onError);
			function innerOnComplete(e:Object):void{
				onComplete(e[0]);
			}
		}
		
		override public function loadUserFriends(onComplete:Function, onError:Function=null):void{
			_sendRequest("friends.get", null, onComplete, onError);
		}
		
		override public function loadUserFriendsProfiles(onComplete:Function, onError:Function=null):void{
			loadUserFriends(innerComplete, onError);
			// обработать непонятный json приходящий от api odnoklassniki
			function innerComplete(e:Object):void{
				if(!(e is Array)) e = [];// вконтакте любит посылать {} заместо []
				loadProfiles((e as Array), onComplete, onError);
			}
		}
		
		override public function loadUserAppFriends(onComplete:Function, onError:Function=null):void{
			_sendRequest("friends.getAppUsers", null, internalComplete, onError);
			function internalComplete(e:Object):void{
				if(e.hasOwnProperty("uids")) e = e["uids"];
				if(!(e is Array)) e = [];// вконтакте любит посылать {} заместо []
				onComplete(e);
			}
		}
		
		
		protected function getStringPermissions(permissions:uint, asArray:Boolean):*{
			var permissionsArray:Array = [];
			if(PERMISSION_WALL_USER_MASK & permissions) permissionsArray.push("PUBLISH TO STREAM");
			if(PERMISSION_STATUS_MASK & permissions) permissionsArray.push("SET STATUS");
			if(PERMISSION_PHOTO_MASK & permissions) permissionsArray.push("PHOTO CONTENT");
			
			if(asArray)
				return permissionsArray;
			else
				return permissionsArray.join();
		}
		
		
		private var wishSettings:* = null;// хранит настройки, которые последними пытались быть выставлены
		override public function showSettingsBox(settings:*=null):Boolean{
			if(ForticomAPI.connected && !wishSettings/*и не рпоисходит выставление других настроек*/){
				ForticomAPI.removeEventListener(ForticomAPI.CALL_BACK, onSettingsChanged);
				ForticomAPI.addEventListener(ForticomAPI.CALL_BACK, onSettingsChanged);
				ForticomAPI.showPermissions(getStringPermissions(settings, true))
				return true;
			}
			return false;
		}
		
		private function onSettingsChanged(e:Event):void{
			ForticomAPI.removeEventListener(ForticomAPI.CALL_BACK, onSettingsChanged);
			throw new Error("Дописать обработку изменения настроек приложения");
		}
		
		override public function showInviteBox():Boolean{
			if(ForticomAPI.connected){
				ForticomAPI.showInvite(type?type:"Играйте вместе со мной!", "blablabla");
				return true;
			}
			return false;
		}
		
		override public function showPaymentBox(socialMoney:Number, onSuccess:Function=null, title:String=null, message:String=null, code:String=null, params:Object=null):Boolean
		{
			if(ForticomAPI.connected){
				ForticomAPI.showPayment(title, message, code, int(socialMoney));
				return true;
			}
			return false;
		}
		
		
		public var images:Dictionary = new Dictionary();
		override public function wallPost(recipient:SocialUser=null, title:String=null, message:String=null, 
										  image:*=null, imageUrl:String=null, postData:String=null, 
										  onComplete:Function=null, onError:Function=null, additionParams:Object=null):Boolean{
			
			var m : String = message;			
			message = title; 
			title = m;
			
			if(wallPostLimit)
			{
				onError && onError({"error":"wall.limit", "error_code":1});
				return onError != null;
			}
			
			if(images[imageUrl]) {
				imageUrl = images[imageUrl];
				if(additionParams && additionParams.imagePostfix) {
					var ind : int = imageUrl.lastIndexOf('.');
					if(ind != -1) {
						imageUrl = imageUrl.substr(0,ind)+additionParams.imagePostfix+imageUrl.substr(ind);
					}
					delete additionParams.imagePostfix;
				}
			} else {
				trace("No image in images dictionary for " + imageUrl);
			}
			
			if(recipient == null)
				recipient = user;
			
			
			var attachment:Object = {"caption": title.substr(0,128), "media":[{"href":postData,
				"src": imageUrl,"type":"image"}]};
			var action_links:Object = [{"text": additionParams["linkText"],"href":postData}];
			var data:Object = 	{"message": message, "attachment": JSON.encode(attachment), "action_links": JSON.encode(action_links)}
			
			if(false && super.wallPost(recipient)){// HOOK потому что в одноклассниках фактически каждый раз нужно просить пермишн, кода постишь
				directWallPost(data, onComplete, onError);
				return true;
			}else{
				// необходимо сначала выставить настройки
				onWallStreamPermission(arguments, data, (additionParams && additionParams.permissionTitle?additionParams.permissionTitle:(title?title:"Allow posting")));
				return true;
			}	
			return false;
		}
		
		
		/**
		 * Послать уже готовые data напрямую на сервер
		 */
		private var wallPostLimit:Boolean = false;
		protected function directWallPost(data:Object, onComplete:Function, onError:Function):void{
			_sendRequest("stream.publish", data,
				function(e:Object):void{onComplete && onComplete();}, 
				function(e:Object):void{
					wallPostLimit = (e && e["error_code"] && e["error_code"] == 11);
					if(onError){
						if(wallPostLimit)
							onError({"error":"wall.limit", "error_code":1});
						else
							onError();
					}
				});
		}
		
		
		
		//Когда пользователь пытается постить на свою стену, не выставив натсройку "stream"		 
		//Функция пытается выставить настройку и, если будет выставлена, запостить как "stream"
		private var lastWallStreamPermArgs:Array;// хранит аргументы, переданные последней вызванной функции onWallStreamPermission
		private var lastWallStreamData:Object;
		private function onWallStreamPermission(args:Array, data:Object, permissionTitle:String):void{
			lastWallStreamPermArgs = args;
			ForticomAPI.removeEventListener(ForticomAPI.CALL_BACK, onWallStreamPermissionSuccess);
			ForticomAPI.addEventListener(ForticomAPI.CALL_BACK, onWallStreamPermissionSuccess);
			data["method"] = "stream.publish";
			if (!user.itsMe) data["uid"] = user.id;
			data["format"] = "JSON";
			data["application_key"] = flashVars["application_key"];
			if (user.itsMe) data["session_key"] = flashVars["session_key"];
			_createSignature(data);
			ForticomAPI.showConfirmation("stream.publish", permissionTitle, data["sig"]);
			lastWallStreamData = data;
		}
		// callback на изменение настроек приложения
		private function onWallStreamPermissionSuccess(e:Event):void{
			ForticomAPI.removeEventListener(e.type, arguments.callee);
			trace("Posting callback");
			if(Object(e).hasOwnProperty("result") && Object(e)["result"] == "ok"){
				trace("Posting success");
				lastWallStreamData["resig"] = Object(e).data;
				directWallPost(lastWallStreamData, lastWallStreamPermArgs[6], lastWallStreamPermArgs[7]);
			}else{
				trace("Posting error");
			}
		}
		
		
		override protected function _isAppUser():Boolean{
			return flashVars["authorized"] == 1;
		}
		
		
		
		override protected function _getApiUrl(method:String, request:Object=null):String{
			return (flashVars["api_server"]?flashVars["api_server"]:"http://195.218.169.227:8088/") + "fb.do";
		}
		
		protected var call_id:uint = 0;
		override protected function _getUrlVariables(method:String):URLVariables{
			var urlVariables:URLVariables = new URLVariables;
			urlVariables["method"] = method;
			urlVariables["application_key"] = flashVars["application_key"];
			urlVariables["format"] = "JSON";
			if(urlVariables["uid"] == null)
				urlVariables["session_key"] = flashVars["session_key"];
			//urlVariables["call_id"] = call_id++;
			return urlVariables;
		}
		
		override protected function _createSignature(urlVariables:Object):void{
			if(urlVariables["sig"] != null) return;
			var sig : String = '';
			var keys : Array = [], key : String;
			for (key in urlVariables) { keys.push(key);}
			keys.sort();
			var i: int = 0, l : int = keys.length;
			for (i; i < l; i++)
			{
				sig += keys[i] + "=" + urlVariables[keys[i]];
			}
			sig += this.keys;
			//sig += (urlVariables['uid'] != undefined && !exeption) ? <secret> : flashVars["session_secret_key"];
			urlVariables["sig"] = MD5.encrypt(sig).toLowerCase();
		}
		
		override protected function _responseHandler(response:String, onComplete:Function, onError:Function):Boolean{
			if(super._responseHandler(response, onComplete, onError)){
				var serverResponce:Object = _safetyJSONDecode(response, onError);
				if(serverResponce != null){
					if(serverResponce.hasOwnProperty("error_code")){
						onError && onError(serverResponce);
						logError();
					}else{
						onComplete && onComplete(serverResponce);
						return true;
					}
				}else{
					logError(null, '{"text":"' + escape(response) + '"}');
				}
			}
			return false;
		}
	}
}
