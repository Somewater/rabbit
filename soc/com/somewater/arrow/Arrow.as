package com.somewater.arrow
{
	import flash.display.*
	import com.somewater.social.SocialAdapter;
	import com.somewater.social.SocialUser;

	//import flash.events.Event;
	//import flash.text.*
	//import flash.net.URLVariables;
    //import flash.utils.setTimeout;

    //[Embed(source="arrow.swf", symbol="HintArrow")]
	public class Arrow extends Sprite
	{
		protected var social:SocialAdapter;
		//private var textField:TextField;
		//private static var instance:Arrow;

		/*public function Arrow():void
		{
			textField = new TextField();
			textField.wordWrap = textField.multiline = true;
			textField.width = 300;
            textField.height = 600;
			addChild(textField);
			instance = this;

			createSocial();
			t("INIT ME");
			//var fv:URLVariables = new URLVariables('access_token=f6665b62b8ac86d8f62875157ff679ff514f665f66598e7255a73b253fec432&api_id=1860789&api_settings=771&api_url=http%3A%2F%2Fapi.vkontakte.ru%2Fapi.php&auth_key=c6ecc613d4f0a668d33b7c9402cd0792&debug=0&domain=vkontakte.ru&group_id=0&hash=&height=590&is_app_user=1&language=0&lc_name=8af96de5&parent_language=0&referrer=menu&scale=1&secret=0129b0252c&sid=b45bb8edb6d86a4a08adc48c85aa2ee878308032c5443115307817cc74887c&swf_url=http%3A%2F%2Fcs5741.vkontakte.ru%2Fu245894%2Fef35f826029a15.zip&user_id=245894&viewer_id=245894&viewer_type=2&width=606');
			//init({"stage":fv,"key":"","complete":onCompleteExecTests,"error":function():void{t('ERROR!!!')}});
            var self:* = this;
            if(stage)
                init({"stage":self,"complete":onCompleteExecTests,"error":function():void{t('ERROR!!!')}});
            else
                addEventListener(Event.ADDED_TO_STAGE, function(e:Event):void{
                    init({"stage":self,"complete":onCompleteExecTests,"error":function():void{t('ERROR!!!')}});
                })
		}*/

		protected function createSocial():void
		{
			//social = new VkontakteSocialAdapter();
			throw new Error("Override me");
		}

		/*public static function t(msg:*):void
		{
			var message:String = String(msg);
			trace(message);
			instance.textField.appendText(message + "\n");
		}


        private function onCompleteExecTests():void
        {
            t("Completed/ tests started");
            var arr:Array;
            try
            {
                arr = getFriends();
                 if(try_length(arr) == false) throw new Error("Empty friends")
                t('[SUCCESS] friend');
            }catch(err:Error){t('[FAIL] friends')}

            try
            {
                arr = getAppFriends();
                if(try_length(arr) == false) throw new Error("Empty app friends")
                t('[SUCCESS] app friend');
            }catch(err:Error){t('[FAIL] app friends')}

            try
            {
                if(getUser().firstName == null || getUser().firstName.length == 0) throw new Error("Empty user data")
                t('[SUCCESS] user');
            }catch(err:Error){t('[FAIL] user')}

            try
            {
                showInviteWindow();
                t('[SUCCESS] invite success');
            }catch(err:Error){t('[FAIL] invite throw error')}

            setTimeout(function():void{
                try
                {
                    pay(1, function():void{t('[SUCCESS] pay callback (y)')}, function():void{t('[SUCCESS] pay callback (n)')})
                    t('[SUCCESS] get pay');
                }catch(err:Error){t('[FAIL] pay throw error')}
            }, 10000)

            try
            {
                getUsers(["1","2","3"], function(...args):void{t('[SUCCESS] users callback (y)')}, function(...args):void{t('[SUCCESS] users callback (n)')})
                t('[SUCCESS] get users');
            }catch(err:Error){t('[FAIL] getUsers throw error')}

            function try_length(arr:Array):Boolean
            {
                for each(var item:* in arr)
                    return true;
                return false;
            }
        }*/
		
		////////////////
		//
		//		IMPL
		//
		///////////////

		public function get data():Object
		{
			return social;
		}

		public function get flashVars():Object
		{
			return social.flashVars;
		}
		
		public function init(params:Object):void
		{
			social.init(params['stage'], params['complete'], params['error'], params['key']);
		}
		
		public function get hasUserApi():Boolean
		{
			return true;
		}
		
		public function get hasFriendsApi():Boolean
		{
			return true;
		}
			
		public function getFriends():Array
		{
			return social.getFriends();
		}
			
		public function getAppFriends():Array
		{
			return social.getAppFriends();
		}
			
		public function getUser():SocialUser
		{
			return social.user;
		}
			
		public function showInviteWindow():void
		{
			social.showInviteBox();
		}

        /**
         *
         * @param quantity
         * @param onSuccess
         * @param onFailure
         * @param params {title, message, code, ...}
         */
		public function pay(quantity:Object, onSuccess:Function, onFailure:Function, params:Object = null):void
		{
			var result:Boolean = social.showPaymentBox(Number(quantity), onSuccess,
                                                        (params ? params['title'] : null),
                                                        (params ? params['message'] : null),
                                                        (params ? params['code'] : null), params);
			if(result == false)
				onFailure && onFailure();
		}
			
		public function getUsers(uids:Array, onComplete:Function, onError:Function):void
		{
			social.getProfiles(uids, onComplete, onError);
		}

		public function posting(user:SocialUser = null, title:String = null, message:String = null, image:* = null, imageUrl:String = null, data:String = null, onComplete:Function = null, onError:Function = null, additionParams:Object = null):void {
			social.wallPost(user, title, message, image, imageUrl, data, onComplete, onError, additionParams);
		}
	}
}
