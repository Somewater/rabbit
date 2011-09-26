package com.somewater.social
{
	import com.progrestar.common.util.JSON;
	
	import flash.events.Event;
	import flash.external.ExternalInterface;
	import flash.net.URLRequest;
	import flash.system.Security;
	import flash.system.System;

	public class Hi5SocialAdapter extends FacebookSocialAdapter
	{
		
		public static const HI5_API : String = 'http://apps.hi5.com/restserver.php';
		
		public function Hi5SocialAdapter()
		{
			super();
			PERMISSION_WALL_FRIEND_MASK = PERMISSION_WALL_APPFRIEND_MASK = 0;
			PAYMENT_SERVER_CHECK = true;			
			networkName = 'T_NETWORK_HI5';
		}
		
		override public function createSocialUser(info:Object):SocialUser{
			var socialUser:SocialUser = new SocialUser();
			socialUser.isAppFriend = info.is_app_user && (info.is_app_user != 'false');
			socialUser.id = info["uid"];
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
		
		override protected function _getApiUrl(method:String, request:Object=null):String{
			return HI5_API;// + "" + "?access_token=" + access_token + "&";
		}

		override protected function preRefresh():void{
			//parcePermissions(); - можно раскомментить, когда север станет присылать permissions			
			if(flashVars["session"] is String){
				flashVars["session"] = JSON.decode(flashVars["session"]);
				keys = flashVars["session"]["access_token"]; // если используется авторизация по Token
			}
			if(flashVars["social"] is String){
				flashVars["social"] = JSON.decode(flashVars["social"]);
			}
			if(!location && flashVars["pstar_loc"]){
				location = flashVars["pstar_loc"];
				trace("*******\n	loc=" + location + "\n*******");
				dispatchEvent(new Event(SocialAdapter.EVENT_LOCATION_CHANGED));
			}			
		}
		
		override public function loadUserProfile(onComplete:Function, onError:Function=null):void{
			onComplete(_initData["user"]);
		}
		
		override protected function getStringPermissions(permissions:uint, asArray:Boolean):*{
			var permissionsArray:Array = [];
			if(PERMISSION_WALL_USER_MASK & permissions) permissionsArray.push("read_stream");
			if(PERMISSION_EMAIL_MASK & permissions) permissionsArray.push("email");
			if(PERMISSION_BOOKMARK_MASK & permissions) permissionsArray.push("bookmarked");
			
			if(asArray)
				return permissionsArray;
			else
				return permissionsArray.join();
		}
		
		override public function wallPost(recipient:SocialUser=null, title:String=null, 
										  message:String=null, image:*=null, imageUrl:String=null, 
										  postData:String=null, onComplete:Function=null, 
										  onError:Function=null, additionParams:Object=null):Boolean {
			if(recipient == null)
				recipient = user;
			/*if(!PERMISSION_WALL_FOR(recipient)){
				// hook, позволяющий продолжить постинг после успешного выставления настроек
				onWallStreamPermission(arguments);
				return true;
			}*/
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
			
			var href:String = application_path + "?pstar_loc=" + postData + "&oid=" + user.id + "&vid=" + recipient.id;	
			var data:Object = {	//"message": message,  // - сообщение в самом верху, рядом с именем постера
				"target_id": recipient.id
			}
			data["attachment"] = {
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
			
			var callback : Function = function(...params) {
				onComplete && onComplete();
			}
			
			data["action_links"] = [{"text":additionParams["linkText"], "href": href}];
			if(ExternalInterface.available) {
				ExternalInterface.addCallback('streamPublishCallback', callback);
				ExternalInterface.call('streamPublish', message, data["attachment"], data["action_links"], recipient.id);
				return true;
			} else {
				return false;
			}
			
			return false;
			
		}
		
		override public function showInviteBox(uid:String=null, type:String=null, onComplete:Function=null, onError:Function=null):Boolean {
			if(ExternalInterface.available) {
				ExternalInterface.call('hi5.Api.inviteFriends');
				return true;
			} else {
				return false;
			}
		}
		override public function showPaymentBox(socialMoney:Number, onSuccess:Function=null, title:String=null, message:String=null, code:String=null, params:Object=null):Boolean
		{
			onSuccess();
			return true;
		}
		
		override public function showRefillSocialMoneyBox() : void {
			if(ExternalInterface.available) {
				ExternalInterface.call('hi5.Api.buyCoins');
			}
		}
		
		override public function get paymentData() : Object {
			var obj : Object = {};
			for(var str : String in flashVars) {
				if(str.substr(0,2)=='fb'){
					obj[str] = flashVars[str];
				}
			}			
				
			return JSON.encode(obj);
		}	
		
		override public function loadUserBalance(onComplete:Function, onError:Function = null):Boolean{
			if(ExternalInterface.available) {
				ExternalInterface.call('hi5.Api.updateCoinsBalance');
				return true;
			}
			return false;
		}
		
		// изменен баланс по событию враппера (или по запросу к api)
		private function onBalanceChanged(e:Object):void{
			dispatchEvent(new Event("onBalanceChanged"));
		}
		
		override protected function _startInitLoading():void {
			
			_initData["user"] = flashVars['social']['response'].user[0];
			_initData["user"].uid = flashVars['social']['response'].uid;
			_initData["user"].locale = flashVars['fb_sig_locale'].split('_')[0];
			
			_initData["groups"] = [];
			_initData["appFriends"] = [];
			
			var friends : Array = flashVars['social']['response'].friends;
			if(friends) {
				var len : uint = friends.length;
				for(var i:uint=0; i<len; i++) {
					var fr : Object = friends[i];
					if(fr && fr.is_app_user!="false") {
						_initData.appFriends.push(fr);
					}
				}
			}
			
			_initData["friends"] = friends
			
			_parseInitData();
		}
		
	}
}