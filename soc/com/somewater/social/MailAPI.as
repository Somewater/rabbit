package com.somewater.social
{
	import com.adobe.crypto.MD5;
	import com.adobe.crypto.MD5;
	import com.progrestar.common.util.JSON;
	
	import flash.display.Loader;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.SecurityErrorEvent;
	import flash.events.TimerEvent;
	import flash.net.URLLoader;
	import flash.net.URLLoaderDataFormat;
	import flash.net.URLRequest;
	import flash.net.URLRequestMethod;
	import flash.net.URLVariables;
	import flash.system.Capabilities;
	import flash.system.LoaderContext;
	import flash.system.Security;
	import flash.utils.Timer;
	
	public class MailAPI
	{
		public function MailAPI()
		{
		}

		public static var params:Object;
		public static var userObject:Object = new Object();
		public static var uid:*;
			
		private static var context:LoaderContext;
		private static var mainPath:String;
		private static var mainRequest:String;
		private static var _parameters:String;
		private static var _crc:String;
		
		private static var apiRequest:URLRequest;
		private static var apiLoader:URLLoader;
		private static var swfLoader:Loader;
		
		private static var inited:Boolean = false;

		public var result:*;
		
		public static var photo_queue:Array = new Array();
		public static var current_photo_queue:Array = new Array(); // queue with currently loading info
		public static var all_photos:Array = new Array();
		private static const API_URL:String="http://www.appsmail.ru/platform/api";
		
		private static var initSuccess:Function;
		private static var initError:Function;
		
		public static var  key:String = "";
		
		public static function init( social:Object, success:Function, error:Function ):Boolean
		{
			if( inited ) return inited;
	 		if( !social ) error();
	 		
	 		initError = error;
	 		initSuccess = success;
	 		params = social;
	 		
			var versionNumber:String = Capabilities.version;
			var versionArray:Array = versionNumber.split(",");
			var length:Number = versionArray.length;
			var platformAndVersion:Array = versionArray[0].split(" ");
			var majorVersion:Number = parseInt(platformAndVersion[1]);
			
			if(majorVersion >= 10)
			{
				Security.allowDomain("*");
				
				uid = params["vid"]+","+params["authentication_key"];
				
				if(params['is_app_user'] == "1")
				{
					var loader:URLLoader = getUserProfilesLoader([params['vid']]);
					loader.addEventListener(Event.COMPLETE, onUserProfileLoaded);
					inited = true;
				}
				else{
					callInitError("notAppUser");
				}
				
			}		
			
			return inited;
		}

		public static function getParams():Object{
			var p:Object = params;
			p['key'] = key;
			return p; 
		}
		
		private static function callInitError( error:String ):void{
			inited = false;
			initError(error);
		}
		
		// InitFlow onUserProfilesLoaded-loadFriendProfiles-onUserFriendsLoaded-onUserFriendsProfilesLoaded-onUserAppFriendsProfilesLoaded-deffered-success
		public static function getUserProfilesLoader(uids:Array):URLLoader
		{
			var apiRequest:URLRequest = new URLRequest(API_URL);
			apiRequest.method = URLRequestMethod.POST;
			
			var apiVariables:URLVariables = new URLVariables();
			apiVariables["api_id"] = params['api_id'];
			apiVariables["session_key"] = params['session_key'];
			apiVariables["method"] = "users.getInfo";
			apiVariables["uids"] = uids.toString();
			apiVariables["sig"] = MD5.hash(params['vid'] + "api_id=" + params['api_id'] + "method="+apiVariables["method"] + "session_key=" + apiVariables["session_key"] + "uids=" + apiVariables["uids"] + key);
			apiRequest.data = apiVariables;
			
			var apiLoader:URLLoader = new URLLoader(apiRequest);
			apiLoader.addEventListener(Event.COMPLETE, defLoaderHandler);
			apiLoader.addEventListener(IOErrorEvent.IO_ERROR, defErrorHandler);
			return apiLoader;
		}
				
		private static function getFriendsLoader():URLLoader
		{
			var apiRequest:URLRequest = new URLRequest(API_URL);
			apiRequest.method = URLRequestMethod.POST;
			var apiVariables:URLVariables = new URLVariables();
			apiVariables["api_id"] = params['api_id'];
			apiVariables["session_key"] = params['session_key'];
			apiVariables["method"] = "friends.get";
			apiVariables["sig"] = MD5.hash(params['vid'] + "api_id=" + params['api_id'] + "method="+apiVariables["method"] + "session_key=" + apiVariables["session_key"] + key);
			apiRequest.data = apiVariables;
			
			var apiLoader:URLLoader = new URLLoader(apiRequest);
			apiLoader.addEventListener(Event.COMPLETE, defLoaderHandler);
			apiLoader.addEventListener(IOErrorEvent.IO_ERROR, defErrorHandler);
			return apiLoader;
		}
		
		private static function getAppFriendsLoader():URLLoader
		{
			var apiRequest:URLRequest = new URLRequest(API_URL);
			apiRequest.method = URLRequestMethod.POST;
			var apiVariables:URLVariables = new URLVariables();
			apiVariables["api_id"] = params['api_id'];
			apiVariables["session_key"] = params['session_key'];
			apiVariables["method"] = "friends.getAppUsers";
			apiVariables["sig"] = MD5.hash(params['vid'] + "api_id=" + params['api_id'] + "method="+apiVariables["method"] + "session_key=" + apiVariables["session_key"] + key);
			apiRequest.data = apiVariables;
			
			var apiLoader:URLLoader = new URLLoader(apiRequest);
			apiLoader.addEventListener(Event.COMPLETE, defLoaderHandler);
			apiLoader.addEventListener(IOErrorEvent.IO_ERROR, defErrorHandler);
			return apiLoader;
		}
				
		private static function defLoaderHandler(e:Event):void{
			e.target.removeEventListener(Event.COMPLETE, defLoaderHandler);
			e.target.removeEventListener(IOErrorEvent.IO_ERROR, defErrorHandler);
		}
		private static function defErrorHandler(e:Event):void{
			e.target.removeEventListener(Event.COMPLETE, defLoaderHandler);
			e.target.removeEventListener(IOErrorEvent.IO_ERROR, defErrorHandler);
			e.target.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, defErrorHandler);
			
			callInitError("API");
		}

		private static function onUserProfileLoaded(e:Event = null):void
		{
			e.target.removeEventListener(Event.COMPLETE, onUserProfileLoaded);
			if(!e.target.data) return;
			
			userObject = JSON.decode(e.target.data.toString());
			if( userObject )
			userObject = userObject[0];
			else userObject = {};
			
			//apiLoader = getSettingsLoader();
			//apiLoader.addEventListener(Event.COMPLETE, onSettingsLoaded);
			
			var apiLoader:URLLoader = getFriendsLoader();
			apiLoader.addEventListener(Event.COMPLETE, onUserFriendsLoaded);
		}
		
		private static function onSettingsLoaded(e:Event = null):void
		{
			e.target.removeEventListener(Event.COMPLETE, onSettingsLoaded);
			var perms:* = JSON.decode(e.target.data as String);
			
			if( !perms.response || !Number(perms.response.notify) || !Number(perms.response.news) || !Number(perms.response.info) ){
				callInitError("permission");
			}else{
				var apiLoader:URLLoader = getFriendsLoader();
				apiLoader.addEventListener(Event.COMPLETE, onUserFriendsLoaded);
			}
		}
		
		private static function onUserFriendsLoaded(e:Event = null):void
		{
			e.target.removeEventListener(Event.COMPLETE, onUserFriendsLoaded);
			
			var ids:* = JSON.decode(e.target.data as String);
			
			if (ids && !ids['error'])
			{
				var uids:Array = [];
				for( var i:* in ids )
					uids.push(ids[i]);
				
				if( uids.length>0 ){
					var apiLoader:URLLoader = getUserProfilesLoader( uids );
					apiLoader.addEventListener(Event.COMPLETE, onUserFriendsProfilesLoaded);
				}else{
					deffered();
					preinitSuccess();
				}
			}
			else
				callInitError("permission");
		}
		
		private static function preinitSuccess():void{
			var ids:Array = new Array();
			ids.push(userObject.uid);
			for( var i:* in userObject.appfriends ) ids.push(userObject.appfriends[i].uid);
			
			var req:URLRequest = new URLRequest( (SocialWrapper.saveSocialInfoUrl.lastIndexOf("?")==-1?SocialWrapper.saveSocialInfoUrl+"?transid":SocialWrapper.saveSocialInfoUrl) );
			req.method = URLRequestMethod.POST;
			req.contentType = "application/octet-stream";
			req.data = new URLVariables();
			var obj:Object = {};
			obj["ids"] = ids;
			obj["transid"] = {"id":params["owner"],"networkLong":params["vid"]};
			req.data =  JSON.encode(obj);
			
			var l:URLLoader = new URLLoader(req);
			l.addEventListener(Event.COMPLETE, defLoaderHandler);
			l.addEventListener(IOErrorEvent.IO_ERROR, defErrorHandler);
			l.addEventListener(Event.COMPLETE, handleTransid );
		}
		
		private static function handleTransid(e:Event):void{
			var resp:String = e.target.data.toString();
			resp && (resp=JSON.decode(resp));
			
			for( var i:* in resp ){
				if( userObject.uid==i ){
					userObject.shortId = resp[i];
				}else{
					for( var j:* in userObject.appfriends ){
						if( userObject.appfriends[j].uid==i ){
							userObject.appfriends[j].shortId = resp[i];
						}
					}
				}
			}
			
			initSuccess();
		}
		
		private static function onUserFriendsProfilesLoaded(e:Event = null):void
		{
			e.target.removeEventListener(Event.COMPLETE, onUserFriendsProfilesLoaded);
			
			userObject.friends = JSON.decode(e.target.data as String);
			//userObject.friends = userObject.friends.response;	
			
			var apiLoader:URLLoader = getAppFriendsLoader();
			apiLoader.addEventListener(Event.COMPLETE, onUserAppFriendsLoaded);
		}
		
		private static function onUserAppFriendsLoaded(e:Event = null):void
		{
			e.target.removeEventListener(Event.COMPLETE, onUserAppFriendsLoaded);
			
			userObject.appfriends = new Array();
			
			var ids:* = JSON.decode(e.target.data as String);
			if( ids ){
				//ids = ids.response;
				
				for( var i:* in ids ){
					for( var j:* in userObject.friends ){
						if( userObject.friends[j].uid == ids[i] ){
							userObject.appfriends.push(userObject.friends[j]);
							continue;
						}	
					}
				}
			}
			
			deffered();
			preinitSuccess();
		}
		
		private static function deffered():void{
			var t:Timer = new Timer(1500,1);
			t.addEventListener( TimerEvent.TIMER, handleDeffered );
			t.start();
		}
		
        private static function isAdmin():Boolean{
        	return false;
        	//var adminIds:Array = ["1", "6492", "457516", "811055", "591364"];
        	//return (adminIds.lastIndexOf(params["viewer_id"])==-1? false:true);
        }
		
		private static function handleDeffered( e:TimerEvent ):void{
			refreshBalance();
		}
		
		private static var moneyBalance:uint;
		public static function getBalance():uint{
			return moneyBalance;
		}
		
		public static function refreshBalance():void{
			//var loader:URLLoader = getBalanceLoader();
			//loader.addEventListener(Event.COMPLETE, handleBalanceLoaded);
		}
		
		private static function handleBalanceLoaded(e:Event ):void{
			
		}
		
		public static function getSettingsLoader():URLLoader{
			var apiRequest:URLRequest = new URLRequest(API_URL);
			apiRequest.method = URLRequestMethod.POST;
			
			var apiVariables:URLVariables = new URLVariables();
			apiVariables["api_id"] = params['api_id'];
			apiVariables["session_key"] = params['session_key'];
			apiVariables["method"] = "my.getUserAppSettings";
			apiVariables["sig"] = MD5.hash(params['vid'] + "api_id=" + params['api_id'] + "method="+apiVariables["method"] + "session_key=" + apiVariables["session_key"] + key);
			apiRequest.data = apiVariables;
			
			var apiLoader:URLLoader = new URLLoader(apiRequest);
			apiLoader.addEventListener(Event.COMPLETE, defLoaderHandler);
			apiLoader.addEventListener(IOErrorEvent.IO_ERROR, defErrorHandler);
			return apiLoader;
		}
		
		private static function repairStringforMD5(str:String):String{
			var u:URLVariables = new URLVariables();
			u['str'] = str;
			
			var str:String = u.toString().substr(4);
			return str;
		}

		public static function sendAppInformer(_post: String, _text: String, _img: int = 0) : URLLoader {
			var apiRequest:URLRequest = new URLRequest(API_URL);
			
			apiRequest.method = URLRequestMethod.POST;
			var apiVariables:URLVariables = new URLVariables();
			apiVariables["api_id"] = params['api_id'];
			apiVariables["session_key"] = params['session_key'];
			//apiVariables["owner"] = params['owner'];
			apiVariables["method"] = "stream.publish";
			apiVariables["img"] = _img.toString();
			apiVariables["post"] = _post;
			apiVariables["text"] = _text;

			var _string: String = params['vid'] + "api_id=" + params['api_id'] + "img=" + apiVariables['img'] + "method=" + apiVariables["method"] + "post=" + (apiVariables["post"]) + "session_key=" + apiVariables["session_key"] + "text=" + (apiVariables["text"]) + key;
			apiVariables["sig"] = com.adobe.crypto.MD5.encrypt(_string);
			//apiVariables["sig"] = MD5.hash(_string);
									
			apiRequest.data = apiVariables;
			
			var apiLoader:URLLoader = new URLLoader(apiRequest);
			apiLoader.dataFormat = URLLoaderDataFormat.TEXT;
			apiLoader.addEventListener(Event.COMPLETE, defLoaderHandler);
			apiLoader.addEventListener(IOErrorEvent.IO_ERROR, defErrorHandler);
			return apiLoader;
		}
		
		private static function getAPILoader(add:Object):URLLoader{
			var k:Array = [];
			var md5:String = params['vid'];
			var p:Object = {
				"api_id":params["api_id"],
				"session_key":params['session_key']
			};
			
			for( var i:* in add ) p[i] = add[i];
			for( var i:* in p ) k.push(i); k = k.sort();
			
			var xmlMail:URLRequest = new URLRequest(API_URL);
				xmlMail.method = URLRequestMethod.POST;
				//xmlVkontakte.data = "api_id=" + params['api_id'] + "&format=JSON&method=photos.getAlbums&v=2.0&sig=" + MD5.hash(params['viewer_id'] + "api_id=" + params['api_id'] + "format=JSONmethod=photos.getAlbumsv=2.0" + key);
				xmlMail.data = "";
			
			for( var i:* in k ){
				xmlMail.data += k[i]+"="+p[k[i]]+"&";
				md5 += k[i]+"="+p[k[i]];
			}
				md5 += key;
				xmlMail.data += "sig="+com.adobe.crypto.MD5.encrypt(md5);
			
			var xmlMailLoader:URLLoader = new URLLoader(xmlMail);
			xmlMailLoader.addEventListener(Event.COMPLETE, defLoaderHandler);
			xmlMailLoader.addEventListener(IOErrorEvent.IO_ERROR, defErrorHandler);
			return xmlMailLoader;
		}
		
		public static function openPayDialog(serviceId:int, serviceName:String, smsPrice:int, otherPrice:int):void{
			var mailLoader:URLLoader = getAPILoader({
												"method":"payments.openDialog",
												"window_id":params["window_id"],
												"service_id":serviceId,
												"service_name":serviceName,
												"sms_price":smsPrice,
												"other_price":otherPrice*100
												});
		}
	}
}


/*

package com.pepyator.Social
{
	import com.adobe.crypto.MD5;
	import com.adobe.crypto.MD5new;
	import com.progrestar.common.util.JSON;
	
	import flash.display.Loader;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.SecurityErrorEvent;
	import flash.events.TimerEvent;
	import flash.net.URLLoader;
	import flash.net.URLLoaderDataFormat;
	import flash.net.URLRequest;
	import flash.net.URLRequestMethod;
	import flash.net.URLVariables;
	import flash.system.Capabilities;
	import flash.system.LoaderContext;
	import flash.system.Security;
	import flash.utils.Timer;
	
	public class MailAPI
	{
		public function MailAPI()
		{
		}

		public static var params:Object;
		public static var userObject:Object = new Object();
		public static var uid;
			
		private static var context:LoaderContext;
		private static var mainPath:String;
		private static var mainRequest:String;
		private static var _parameters:String;
		private static var _crc:String;
		
		private static var apiRequest:URLRequest;
		private static var apiLoader:URLLoader;
		private static var swfLoader:Loader;
		
		private static var inited = false;

		public var result;
		
		public static var photo_queue = new Array();
		public static var current_photo_queue = new Array(); // queue with currently loading info
		public static var all_photos = new Array();
		private static const API_URL="http://appsmail.ru/myapi";
		
		private static var initSuccess:Function;
		private static var initError:Function;
		
		public static var  key = "";
		
		public static function init( social, success:Function, error:Function )
		{
			if( inited ) return inited;
	 		if( !social ) error();
	 		
	 		initError = error;
	 		initSuccess = success;
	 		params = social;
	 		
			var versionNumber:String = Capabilities.version;
			var versionArray:Array = versionNumber.split(",");
			var length:Number = versionArray.length;
			var platformAndVersion:Array = versionArray[0].split(" ");
			var majorVersion:Number = parseInt(platformAndVersion[1]);
			
			if(majorVersion >= 10)
			{
				Security.allowDomain("*");
				
				uid = params["owner"]+","+params["auth_key"];
				
				if(params['is_app_user'] == "1")
				{
					var loader:URLLoader = getUserProfilesLoader([params['owner']]);
					loader.addEventListener(Event.COMPLETE, onUserProfileLoaded);
					inited = true;
				}
				else{
					callInitError("notAppUser");
				}
				
			}		
			
			return inited;
		}

		public static function getParams(){
			var p = params;
			p['key'] = key;
			return p; 
		}
		
		private static function callInitError( error:String ){
			inited = false;
			initError(error);
		}
		
		// InitFlow onUserProfilesLoaded-loadFriendProfiles-onUserFriendsLoaded-onUserFriendsProfilesLoaded-onUserAppFriendsProfilesLoaded-deffered-success
		public static function getUserProfilesLoader(uids:Array):URLLoader
		{
			var apiRequest = new URLRequest(API_URL);
			apiRequest.method = URLRequestMethod.POST;
			
			var apiVariables = new URLVariables();
			apiVariables["api_id"] = params['api_id'];
			apiVariables["token"] = params['token'];
			apiVariables["method"] = "getProfiles";
			apiVariables["uids"] = uids.toString();
			apiVariables["sig"] = MD5.hash(params['owner'] + "api_id=" + params['api_id'] + "method="+apiVariables["method"] + "token=" + apiVariables["token"] + "uids=" + apiVariables["uids"] + key);
			apiRequest.data = apiVariables;
			
			var apiLoader = new URLLoader(apiRequest);
			apiLoader.addEventListener(Event.COMPLETE, defLoaderHandler);
			apiLoader.addEventListener(IOErrorEvent.IO_ERROR, defErrorHandler);
			return apiLoader;
		}
				
		private static function getFriendsLoader():URLLoader
		{
			var apiRequest = new URLRequest(API_URL);
			apiRequest.method = URLRequestMethod.POST;
			var apiVariables = new URLVariables();
			apiVariables["api_id"] = params['api_id'];
			apiVariables["token"] = params['token'];
			apiVariables["method"] = "getFriends";
			apiVariables["sig"] = MD5.hash(params['owner'] + "api_id=" + params['api_id'] + "method="+apiVariables["method"] + "token=" + apiVariables["token"] + key);
			apiRequest.data = apiVariables;
			
			var apiLoader = new URLLoader(apiRequest);
			apiLoader.addEventListener(Event.COMPLETE, defLoaderHandler);
			apiLoader.addEventListener(IOErrorEvent.IO_ERROR, defErrorHandler);
			return apiLoader;
		}
		
		private static function getAppFriendsLoader():URLLoader
		{
			var apiRequest = new URLRequest(API_URL);
			apiRequest.method = URLRequestMethod.POST;
			var apiVariables = new URLVariables();
			apiVariables["api_id"] = params['api_id'];
			apiVariables["token"] = params['token'];
			apiVariables["method"] = "getAppFriends";
			apiVariables["sig"] = MD5.hash(params['owner'] + "api_id=" + params['api_id'] + "method="+apiVariables["method"] + "token=" + apiVariables["token"] + key);
			apiRequest.data = apiVariables;
			
			var apiLoader = new URLLoader(apiRequest);
			apiLoader.addEventListener(Event.COMPLETE, defLoaderHandler);
			apiLoader.addEventListener(IOErrorEvent.IO_ERROR, defErrorHandler);
			return apiLoader;
		}
				
		private static function defLoaderHandler(e:Event){
			e.target.removeEventListener(Event.COMPLETE, defLoaderHandler);
			e.target.removeEventListener(IOErrorEvent.IO_ERROR, defErrorHandler);
		}
		private static function defErrorHandler(e:Event){
			e.target.removeEventListener(Event.COMPLETE, defLoaderHandler);
			e.target.removeEventListener(IOErrorEvent.IO_ERROR, defErrorHandler);
			e.target.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, defErrorHandler);
			
			callInitError("API");
		}

		private static function onUserProfileLoaded(e:Event = null):void
		{
			e.target.removeEventListener(Event.COMPLETE, onUserProfileLoaded);
			if(!e.target.data) return;
			
			userObject = JSON.decode(e.target.data.toString());
			if( userObject )
			userObject = userObject["response"][0];
			else userObject = {};
			
			//apiLoader = getSettingsLoader();
			//apiLoader.addEventListener(Event.COMPLETE, onSettingsLoaded);
			
			var apiLoader:URLLoader = getFriendsLoader();
			apiLoader.addEventListener(Event.COMPLETE, onUserFriendsLoaded);
		}
		
		private static function onSettingsLoaded(e:Event = null):void
		{
			e.target.removeEventListener(Event.COMPLETE, onSettingsLoaded);
			var perms = JSON.decode(e.target.data as String);
			
			if( !perms.response || !Number(perms.response.notify) || !Number(perms.response.news) || !Number(perms.response.info) ){
				callInitError("permission");
			}else{
				var apiLoader:URLLoader = getFriendsLoader();
				apiLoader.addEventListener(Event.COMPLETE, onUserFriendsLoaded);
			}
		}
		
		private static function onUserFriendsLoaded(e:Event = null):void
		{
			e.target.removeEventListener(Event.COMPLETE, onUserFriendsLoaded);
			
			var ids = JSON.decode(e.target.data as String);
			
			if (ids && !ids['error'])
			{
				var uids = [];
				for( var i in ids )
					uids.push(ids[i]);
				
				if( uids.length>0 ){
					var apiLoader = getUserProfilesLoader( uids );
					apiLoader.addEventListener(Event.COMPLETE, onUserFriendsProfilesLoaded);
				}else{
					deffered();
					initSuccess();
				}
			}
			else
				callInitError("permission");
		}
		
		
		private static function onUserFriendsProfilesLoaded(e:Event = null):void
		{
			e.target.removeEventListener(Event.COMPLETE, onUserFriendsProfilesLoaded);
			
			userObject.friends = JSON.decode(e.target.data as String);
			userObject.friends = userObject.friends.response;	
			
			var apiLoader = getAppFriendsLoader();
			apiLoader.addEventListener(Event.COMPLETE, onUserAppFriendsLoaded);
		}
		
		private static function onUserAppFriendsLoaded(e:Event = null):void
		{
			e.target.removeEventListener(Event.COMPLETE, onUserAppFriendsLoaded);
			
			userObject.appfriends = new Array();
			
			var ids = JSON.decode(e.target.data as String);
			if( ids ){
				ids = ids.response;
				
				for( var i in ids ){
					for( var j in userObject.friends ){
						if( userObject.friends[j].uid == ids[i] ){
							userObject.appfriends.push(userObject.friends[j]);
							continue;
						}	
					}
				}
			}
			
			deffered();
			initSuccess();
		}
		
		private static function deffered(){
			var t:Timer = new Timer(1500,1);
			t.addEventListener( TimerEvent.TIMER, handleDeffered );
			t.start();
		}
		
        private static function isAdmin():Boolean{
        	return false;
        	//var adminIds:Array = ["1", "6492", "457516", "811055", "591364"];
        	//return (adminIds.lastIndexOf(params["viewer_id"])==-1? false:true);
        }
		
		private static function handleDeffered( e:TimerEvent ){
			refreshBalance();
		}
		
		private static var moneyBalance:uint;
		public static function getBalance():uint{
			return moneyBalance;
		}
		
		public static function refreshBalance(){
			//var loader:URLLoader = getBalanceLoader();
			//loader.addEventListener(Event.COMPLETE, handleBalanceLoaded);
		}
		
		private static function handleBalanceLoaded(e:Event ){
			
		}
		
		public static function getSettingsLoader(){
			var apiRequest = new URLRequest(API_URL);
			apiRequest.method = URLRequestMethod.POST;
			
			var apiVariables = new URLVariables();
			apiVariables["api_id"] = params['api_id'];
			apiVariables["token"] = params['token'];
			apiVariables["method"] = "my.getUserAppSettings";
			apiVariables["sig"] = MD5.hash(params['owner'] + "api_id=" + params['api_id'] + "method="+apiVariables["method"] + "token=" + apiVariables["token"] + key);
			apiRequest.data = apiVariables;
			
			var apiLoader = new URLLoader(apiRequest);
			apiLoader.addEventListener(Event.COMPLETE, defLoaderHandler);
			apiLoader.addEventListener(IOErrorEvent.IO_ERROR, defErrorHandler);
			return apiLoader;
		}
		
		private static function repairStringforMD5(str:String){
			var u:URLVariables = new URLVariables();
			u['str'] = str;
			
			var str = u.toString().substr(4);
			return str;
		}

		public static function sendAppInformer(_post: String, _text: String, _img: int = 0) : URLLoader {
			var apiRequest = new URLRequest(API_URL);
			
			apiRequest.method = URLRequestMethod.POST;
			var apiVariables = new URLVariables();
			apiVariables["api_id"] = params['api_id'];
			apiVariables["token"] = params['token'];
			//apiVariables["owner"] = params['owner'];
			apiVariables["method"] = "sendAppInformer";
			apiVariables["img"] = _img.toString();
			apiVariables["post"] = _post;
			apiVariables["text"] = _text;

			var _string: String = params['owner'] + "api_id=" + params['api_id'] + "img=" + apiVariables['img'] + "method=" + apiVariables["method"] + "post=" + (apiVariables["post"]) + "text=" + (apiVariables["text"]) + "token=" + apiVariables["token"] + key;
			apiVariables["sig"] = MD5new.encrypt(_string);
			//apiVariables["sig"] = MD5.hash(_string);
									
			apiRequest.data = apiVariables;
			
			var apiLoader:URLLoader = new URLLoader(apiRequest);
			apiLoader.dataFormat = URLLoaderDataFormat.TEXT;
			apiLoader.addEventListener(Event.COMPLETE, defLoaderHandler);
			apiLoader.addEventListener(IOErrorEvent.IO_ERROR, defErrorHandler);
			return apiLoader;
		}
	}
}
*/