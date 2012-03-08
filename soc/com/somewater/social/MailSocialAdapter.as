package com.somewater.social
{
	import com.adobe.serialization.json.JSON;
	
	import flash.events.Event;
	import flash.net.URLVariables;
	import flash.utils.Dictionary;
	import flash.system.Security;
	
	public class MailSocialAdapter extends SocialAdapter
	{
		// просить виджет
		public const PERMISSION_WIDGET_MASK:int = 16;
		
		
		public function MailSocialAdapter()
		{
			PERMISSIONS = 1;// помеченные "1" нижеследующие функции работают всегда (без необходимости выставлять настройки)

			PERMISSION_NOTIFICATION_MASK = 2;
			PERMISSION_FRIENDS_MASK = 1;// всегда работает	
			PERMISSION_WALL_USER_MASK = 1;// себе в stream можно постить только по настройке (иначе предусмотреть постинг в гостевую книгу себе)
			PERMISSION_WALL_FRIEND_MASK = PERMISSION_WALL_APPFRIEND_MASK = 1;// в гостевые книги друзей можно постить всегда
			PERMISSION_PHOTO_MASK = 8;
			
			super();
			
			DEFAULT_PERMISSION_MASK |= PERMISSION_WALL_USER_MASK;
			DEFAULT_PERMISSION_MASK ^= PERMISSION_WALL_USER_MASK;
			MANDATORY_PERMISSION_MASK = 0;
		}
		
		override public function get networkUrlAddress():String
		{
			return "http://my.mail.ru";
		}
		
		override public function get app_id():String
		{
			return flashVars["app_id"];
		}
		
		override public function get PERMISSION_WALL_USER():Boolean { 
			return super.PERMISSION_WALL_USER;// себе можно постить в любом случае (если не stream то в гостевую, но stream предпочтительнее) 
		}
		
		override public function refresh(...args):void{
			if(!MailruCall.isInited){
				Security.allowDomain ( '*' );
				MailruCall.init("flash-app", keys);
				MailruCall.addEventListener(Event.COMPLETE, onMailruCallComplete);
			}else
				super.refresh();
		}
		
		protected function onMailruCallComplete(e:Event):void{
			MailruCall.removeEventListener(Event.COMPLETE, onMailruCallComplete);
			MailruCall.addEventListener('app.readHash', onLocationChanged);
            MailruCall.exec('mailru.app.utils.hash.read', onLocationChanged);
			parcePermissions();
			super.refresh();
		}
		
		protected function onLocationChanged(e:MailruCallEvent):void{
			if(e.data == null || e.data == "" || e.data[""] == "") return;
			if(e.data["loc"])
				location = e.data["loc"];
			else
				location = JSON.encode(e.data);
			dispatchEvent(new Event(SocialAdapter.EVENT_LOCATION_CHANGED));
		}
		
		/**
		 * Перевести настройки в стиле мейл.ру "настройка1,настройка2,настройка3" в битовые маски переменной PERMISSIONS
		 */
		protected function parcePermissions():void{
			var lastPerm:int = PERMISSIONS;// сохранить старое значение
			PERMISSIONS = 1;// функции соц. сети с маской "1" работают всегда
			
			// если в новых настройках разрешена "notification" или она уже была выставлена ранее 
			// (mail api не возвращает старые настройки, а лишь те, которые были добавлены в данный момент)
			if(flashVars["ext_perm"].indexOf("notification") != -1 || (lastPerm & PERMISSION_NOTIFICATION_MASK)) PERMISSIONS |= 2;
			
			if(flashVars["ext_perm"].indexOf("stream") != -1) PERMISSIONS |= 4;
			
			if(flashVars["ext_perm"].indexOf("widget") != -1) PERMISSIONS |= PERMISSION_WIDGET_MASK;
		}
		
		/**
		 * Перевести числовое представление настроек в принятое в мейл.ру
		 * @param permissions
		 * @param assArray возвратить массив ["perm1", "perm2"] или стринг "perm1,perm2"
		 */
		protected function getStringPermissions(permissions:uint, asArray:Boolean):*{
			var permissionsArray:Array = [];
			if(PERMISSION_NOTIFICATION_MASK & permissions) permissionsArray.push("notification");
			if(PERMISSION_WALL_USER_MASK & permissions) permissionsArray.push("stream");
			if(PERMISSION_WIDGET_MASK & permissions) permissionsArray.push("widget");

			if(asArray)
				return permissionsArray;
			else
				return permissionsArray.join();
		}
		
		override public function createSocialUser(info:Object):SocialUser{
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
				socialUser.bdate = d.time * 0.001;
			}
			return socialUser;
		}
		
		override public function get authentication_key():String{
			return flashVars["authentication_key"];
		}

		override public function loadProfiles(uids:Array, onComplete:Function, onError:Function=null):void{
			// посылаем не более 80 за раз, чтобы счастливые обладатели IE тоже могли наслаждаться играми
			var received:Array = [];
			
			if(uids.length)
				getNextProfiles();
			else
				onComplete && onComplete([]);
			
			function getNextProfiles():void{
				MailruCall.exec("mailru.common.users.getInfo", onInnerComplete, uids.splice(0, Math.min(80, uids.length)));
			}
			
			function onInnerComplete(profiles:Array):void{
				received = received.concat(profiles);
				
				if(uids.length){
					getNextProfiles();
				}else{
					onComplete(received);
				}
			}		
		}
		
		override public function loadUserProfile(onComplete:Function, onError:Function=null):void{
			MailruCall.exec("mailru.common.users.getInfo", innerOnComplete);
			function innerOnComplete(e:Object):void{
				onComplete(e[0])
			}
		}
		
		override public function loadUserFriends(onComplete:Function, onError:Function=null):void{
			trace("Platform does not support \"loadUserFriends\" method. Recommended use \"loadUserFriendsProfiles\" method instead of this");
			loadUserFriendsProfiles(innerComplete, onError);
			function innerComplete(e:Array):void{
				var uids:Array = [];
				for(var i:int = 0;i<e.length;i++)
					uids.push(e[i]["uid"]);
				onComplete(uids);
			}
		}
		
		override public function loadUserFriendsProfiles(onComplete:Function, onError:Function=null):void{
			MailruCall.exec("mailru.common.friends.getExtended", onComplete);
		}
		
		override public function loadUserAppFriends(onComplete:Function, onError:Function=null):void{
			MailruCall.exec("mailru.common.friends.getAppUsers", onComplete);
		}
		
		override public function showInstallBox(settings:*=null):Boolean{
			if(MailruCall.isInited){
				MailruCall.addEventListener("app.applicationInstallation", function(e: MailruCallEvent):void{
					MailruCall.removeEventListener("app.applicationInstallation", arguments.callee);
					if(e.data.status == "success"){
						flashVars["is_app_user"] = 1;
						if(e.data.permissionType){
							flashVars["ext_perm"] = e.data.permissionType;
							parcePermissions();
						}
						dispatchEvent(new Event(SocialAdapter.EVENT_INSTALL_APP_COMPLETE));
					}
				});
				MailruCall.exec("mailru.app.users.requireInstallation",null, getStringPermissions(DEFAULT_PERMISSION_MASK, true));
				return true;
			}
			return false;
		}
		
		override public function showSettingsBox(settings:*=null):Boolean{
			if(MailruCall.isInited)
			{
				// удалить листенеры, на случай, если они ранее уже были установлены
				MailruCall.removeEventListener("app.permissionDialogStatus", onSettingsChanged);
				MailruCall.removeEventListener("common.permissionChanged", onSettingsChanged);	
				
				MailruCall.addEventListener("app.permissionDialogStatus", onSettingsChanged);// на ответ о неудаче или открытии окна
				MailruCall.addEventListener("common.permissionChanged", onSettingsChanged);// на ответ об изменении настроек
            	MailruCall.exec("mailru.common.users.requirePermission",null,getStringPermissions(settings == null?DEFAULT_PERMISSION_MASK: settings, false));
				return true;
			}
			return false;
		}
		
		override public function showInviteBox():Boolean{
			if(MailruCall.isInited){
				MailruCall.exec("mailru.app.friends.invite");
				return true;
			}
			return false;
		}
		
		/**
		 * @param socialMoney стоимость в usd
		 * ...
		 * @param params.other_price:uint стоимость услуги в копейках (можно не задавать, тогда высчитывается согласно socialMoney)
		 * @param params.other_price_only:Boolean если true, то оплата sms не появляется (params.other_price должен быть задан!)
		 */
		override public function showPaymentBox(socialMoney:Number, onSuccess:Function=null, title:String=null, message:String=null, code:String=null, params:Object=null):Boolean
		{
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
					paymentParams["other_price"] = socialMoney*2500
				}
				
				if(onSuccess != null){
					MailruCall.addEventListener("app.incomingPayment", incomingPayment);
					MailruCall.addEventListener("app.paymentDialogStatus", paymentDialogStatus);
				}
				MailruCall.exec("mailru.app.payments.showDialog", null, paymentParams);
				return true;
			}
			return false;
			
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
		/** картинки для стрима */		
		public var images:Dictionary = new Dictionary();
		/**
		 * Может вообще не отработать (без вызова onError) если пользователь постит себе и
		 * на предложение разрешить "stream" жмет нет
		 */		
		override public function wallPost(recipient:SocialUser=null, title:String=null, message:String=null, 
								image:*=null, imageUrl:String=null, postData:String=null, 
								onComplete:Function=null, onError:Function=null, additionParams:Object=null):Boolean{
			trace(images[imageUrl], imageUrl);

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
				trace("No image adress: " + imageUrl);
						
			if(recipient == null)
				recipient = user;
			if(super.wallPost(recipient) || recipient.itsMe){// hook, себе можно постить всегда (ожидая, что пользователь выставит настройку по требованию)
				var stream:Boolean = recipient.itsMe && PERMISSION_WALL_USER;// если это постинг самому игроку и stream разрешен, то постим stream. Иначе в гостевую книгу
				
				var publishListenerName:String = (stream?"common.streamPublish":"common.guestbookPublish");
				
				if(title) title = title.replace(/\"/g,"''");
				if(title) title = (title.length >  400?title.substr(0, 397) + "...":title);
				if(message) message = message.replace(/\"/g,"''");
				if(message) message = (message.length >  400?message.substr(0, 397) + "...":message);
				
				
				var data:Object = {
					"title": title, 
					"text": message, 
					"img_url": imageUrl//120px × 60px (stream)  или  420px × 280px (guestbook)
				};
				if(!stream) data["uid"] = recipient.id;
				
				if(!additionParams)	additionParams = {};
				if(!additionParams["linkText"] && additionParams["playTo"])
					additionParams["linkText"] = additionParams["playTo"];
				if(!additionParams["linkText"] && additionParams["name"])
					additionParams["linkText"] = additionParams["name"];
				if(!additionParams["linkText"])
					additionParams["linkText"] = "Play";
				
				
				
				// очистить все текстовые поля от символа "
				
				
				additionParams["linkText"] = additionParams["linkText"].replace(/\"/g,"''");
				additionParams["linkText"] = (additionParams["linkText"].length >  20?additionParams["linkText"].substr(0, 17) + "...":additionParams["linkText"]);
				
				
				data["action_links"] = [{"text": additionParams["linkText"], "href": "loc=" + postData}];
				
				if(additionParams["linkText2"])
					data["action_links"].push({"text": additionParams["linkText2"], "href": "loc=" +
						(additionParams["postData2"]?additionParams["postData2"]:postData)});
				
				MailruCall.addEventListener(publishListenerName, function(e:MailruCallEvent):void{
					if(e.data.status == "publishSuccess"){
						trace("wallPost.publishSuccess " + e.data.status);
						onComplete && onComplete();
						MailruCall.removeEventListener(publishListenerName, arguments.callee);
					}else if(e.data.status == "authError" || e.data.status == "closed" || e.data.status == "publishFail"){
						trace("wallPost.publishFail " + e.data.status);
						onError && onError();
						MailruCall.removeEventListener(publishListenerName, arguments.callee);
					}
				});
				var postMethod:String = stream?"mailru.common.stream.publish":"mailru.common.guestbook.publish";
				MailruCall.exec(postMethod, null, data);
				MailruCall.createLastCallback(postMethod, data);// запоминаем параметры запроса, чтобы восстановить их на случай логирования ошибки api
				return true;
			}		
			return false;
		}
		
		/*
		//Когда пользователь пытается постить на свою стену, не выставив натсройку "stream"		 
		//Функция пытается выставить настройку и, если будет выставлена, запостить как "stream"
		private var lastWallStreamPermArgs:*;// хранит аргументы, переданные последней вызванной функции onWallStreamPermission
		private function onWallStreamPermission(args:Array):void{
			lastWallStreamPermArgs = args;
			removeEventListener(SocialAdapter.EVENT_PERMISSION_CHANGED, onWallStreamPermissionSuccess);
			addEventListener(SocialAdapter.EVENT_PERMISSION_CHANGED, onWallStreamPermissionSuccess);
			showSettingsBox(PERMISSION_WALL_USER_MASK);
		}
		// callback на изменение настроек приложения
		private function onWallStreamPermissionSuccess(e:Event):void{
			if(PERMISSION_WALL_USER)
				wallPost.apply(this, lastWallStreamPermArgs);
		}
		*/
		
		
		
		
		override protected function _isAppUser():Boolean{
			return flashVars["is_app_user"] == 1;
		}
		


		
		//////////////////////////////////////////////////////
		//
		//					PRIVATE
		//
		//////////////////////////////////////////////////////
		
		
		// листенер на события wrapper
		private function onSettingsChanged(e:MailruCallEvent):void{
			if(e.data.status == "success"){
				if(e.data.permissionType){
					flashVars["ext_perm"] = e.data.permissionType;
					parcePermissions();
				}
				// удалить листенеры, т.к. они более не нужны		
				MailruCall.removeEventListener("app.permissionDialogStatus", onSettingsChanged);
				MailruCall.removeEventListener("common.permissionChanged", onSettingsChanged);	
					
				dispatchEvent(new Event(SocialAdapter.EVENT_PERMISSION_CHANGED));
			}
		}
	}
}
