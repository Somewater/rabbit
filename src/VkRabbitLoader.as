package {
	import adapp.AdAppUtil;

	import clickozavr.Clickozavr;
	import clickozavr.ClickozavrEvent;
	import clickozavr.ContainerInfo;

	import com.somewater.arrow.ArrowVkcom;

	import com.somewater.net.SWFDecoderWrapper;
	import com.somewater.rabbit.Stat;
	import com.somewater.rabbit.loader.EvaRabbitLoader;
	import com.somewater.rabbit.loader.SocialRabbitLoader;
	import com.somewater.rabbit.storage.Config;
	import com.somewater.rabbit.storage.Lib;
	import com.somewater.social.SocialUser;

	import flash.display.DisplayObject;
	import flash.display.Loader;
	import flash.display.LoaderInfo;
	import flash.display.Sprite;
	import flash.events.DataEvent;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.events.SecurityErrorEvent;
	import flash.net.URLRequest;
	import flash.net.navigateToURL;
	import flash.system.ApplicationDomain;
	import flash.system.LoaderContext;
	import flash.system.Security;
	import flash.system.SecurityDomain;
	import flash.utils.getDefinitionByName;

	import ru.evast.integration.IntegrationProxy;

	import ru.evast.integration.core.SocialNetworkTypes;
	import ru.evast.integration.inner.VK.VKInnerAdapter;


	[SWF(width="810", height="650", backgroundColor="#FFFFFF", frameRate="30")]
	public class VkRabbitLoader extends EvaRabbitLoader{

		include 'com/somewater/rabbit/include/RuPreloaderAsset.as';

		/*
		На память:
		 method=execute&uids={viewer_id}&format=json&v=2.0&code=return{"friends":API.getProfiles({"uids":API.getFriends(),"fields":"uid,first_name,last_name,photo,sex"}),"appFriends":API.getAppFriends(),"user":API.getProfiles({"uids":{viewer_id},"fields":"uid,first_name,last_name,nickname,sex,bdate,photo,photo_medium,photo_big,has_mobile,rate"}),balance:API.getUserBalance(),"groups":API.getGroups(),city:API.getCities({"cids":API.getProfiles({"uids":{viewer_id},"fields":"city"})@.city}),country:API.getCountries({"cids":API.getProfiles({"uids":{viewer_id},"fields":"country"})@.country})};
		 */
		public function VkRabbitLoader() {
			super();
			Config.memory['autoPostLevelPass'] = false;
			Config.memory['disableFriendBarInviteBox'] = true;
		}

		override protected function netInitialize():void
		{
			IntegrationProxy._socialNetworkType = SocialNetworkTypes.VKONTAKTE;
			apiAdapter = IntegrationProxy._adapter = new VKInnerAdapter();
			apiAdapter.init(flashVars, DESKTOP_MODE);
			super.netInitialize();
		}

		override protected function onNetInitializeComplete(...args):void {
			if(!postingCode){
				if(flashVars['request_key'])
					_postingCode = String(flashVars['request_key']).split('-');
				else if(flashVars['user_id'] && flashVars['user_id'] != flashVars['viewer_id'])
					_postingCode = ['fip', flashVars['user_id']];
				else if(flashVars['referrer'] == 'request' && getAppFriends().length == 0)
					_postingCode = ['fip', (getAppFriends()[0] as SocialUser).id];
			}
			super.onNetInitializeComplete(args);
		}

		private function navigateToGame(...args):void
		{
			navigateToURL(new URLRequest("http://" + 'vk.com' + '/app' + flashVars['api_id'] + '_' + flashVars['poster_id'] +
					'?from_id=' + flashVars['user_id'] + '&loc=' + flashVars['post_id']), '_blank')
		}

		override protected function createSpecificPaths():void
		{
			basePath = 'http://vk.rabbit.atlantor.ru/';
			var static_server_path:String = 'http://krolgame.static1.evast.ru/VK/';
			swfs = {
						"Game":{priority:-1,preload:true,url:static_server_path + "r0/RabbitGame.swf?cb=12"}
						,"Application":{priority:-1000, preload:true,url:static_server_path + "r0/RabbitApplication.swf?cb=12"}
						,"Lang":{priority:100, preload:true, url:static_server_path + "r0/lang_pack.swf?cb=11"}
						,"XmlPack":{preload:true, url:static_server_path + "r0/xml_pack.swf?cb=12"}

						,"Interface":{preload:true, url:static_server_path + "r0/assets/interface.swf?cb=12"}
						,"Assets":{preload:true, url:static_server_path + "r0/assets/rabbit_asset.swf"}
						,"Rewards":{preload:true, url:static_server_path + "r0/assets/rabbit_reward.swf"}
						,"Images":{preload:true, url:static_server_path + "r0/assets/rabbit_images.swf"}
						,"MusicMenu":{url:static_server_path + "r0/assets/music_menu.swf"}
						,"MusicGame":{url:static_server_path + "r0/assets/music_game.swf"}
						,"Sound":{preload:true, url:static_server_path + "r0/assets/rabbit_sound.swf"}
						,"Font":{priority:100, preload:true, url:static_server_path + "r0/assets/fonts_" + this.locale + ".swf"}
					}

			var i:int = 0;
			var static_posting_path:String = static_server_path + 'r0/posting/';
			for (i = 0; i <= 31;i++)
				filePaths['level_pass_posting_' + i] = static_posting_path + 'levels/level_' + i + '.jpg';
			for (i = 0; i <= 79;i++)
				filePaths['reward_posting_' + i] = static_posting_path + 'rewards/reward_' + i + '.jpg';
			filePaths['friends_invite_posting'] =static_posting_path +  'friends_invite_posting.jpg';
		}

		override public function get net():int { return 2; }


		override public function get referer():String {
			var result:String;
			if(flashVars['user_id'] && String(flashVars['user_id']).length && String(flashVars['user_id']) != '0' && flashVars['user_id'] != flashVars['viewer_id'])
				result = flashVars['user_id']
			else if(flashVars['poster_id'] && String(flashVars['poster_id']).length && String(flashVars['poster_id']) != '0')
				result = flashVars['poster_id']
			else
				result = super.referer;
			if(!result && postingCode){
				var locationParams:Array = postingCode.slice();
				if(locationParams.length > 1 && /^\d+$/.test(locationParams[1]))
					result = locationParams[1];
			}
			return result;
		}

		override public function get hasNavigateToHomepage():Boolean {
			return true
		}

		override public function navigateToHomePage(userId:String):void {
			if(!getCachedUser(userId) || !getCachedUser(userId).homepage)
				navigateToURL(new URLRequest("http://" + 'vk.com' + '/id' + userId), '_blank');
			else
				super.navigateToHomePage(userId);
		}

		override public function get hasPaymentApi():Boolean {
			return true;
		}

		private var _customHash:Object
		override public function get customHash():Object {
			if(_customHash == null)
			{
				_customHash = super.customHash;
				_customHash['GAME_TESTERS']=""
				_customHash['NET_MONEY'] = function(quntity:int):String{
					if(quntity == 1)
						return 'голос';
					else if(quntity < 5)
						return 'голоса';
					else
						return 'голосов';
				};
			}
			return _customHash;
		}


		override public function posting(user:SocialUser = null, title:String = null, message:String = null, image:* = null, imageUrl:String = null, data:String = null, onComplete:Function = null, onError:Function = null, additionParams:Object = null):void {
			if(!user || user.itsMe){
				var gameLink:String = additionParams ? additionParams['game_link'] : null;
				if(!gameLink) gameLink = 'http://vk.com/app' + flashVars['api_id'];
				message += ' ' + gameLink + (data ? '#' + data : '')
			}
			super.posting(user, title, message, image, imageUrl, data, onComplete, onError, additionParams);
		}

		override public function get asyncPayment():Boolean {
			return true;
		}
	}
}
