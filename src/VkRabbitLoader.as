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
		}

		override protected function netInitialize():void
		{
//			arrow = new ArrowVkcom();
//			arrow.addEventListener('wall_view_inline',onWallViewInline);
//			arrow.addEventListener('wall_post_inline',onWallPostInline);
//			onArrowComplete('hjli32ls');

			IntegrationProxy.init(flashVars, SocialNetworkTypes.AUTO_DETECT);
			super.netInitialize();
		}

		private function onWall():void
		{
			_content.y= _popups.y = _tooltips.y = _cursors.y = 0;//revert ads offset
			preloader.scaleX = preloader.scaleY = 0.8;
			preloader.x += 0;
			preloader.y += -30;
		}

		private function onWallViewInline(...args):void {
			onWall();
			preloader.bar.textField.text = 'Играть!';
			preloader.bar.textField.mouseEnabled = false;
			preloader.bar.useHandCursor = preloader.bar.buttonMode = true;
			stage.addEventListener(MouseEvent.MOUSE_DOWN, navigateToGame);
			createSpecificPaths();
			Lib.Initialize(swfADs);
			loadSwf('PostingPopup', function():void{
				var popup:Sprite = Lib.createMC('images.PostingPopup')
				popup.addEventListener(MouseEvent.MOUSE_DOWN, navigateToGame)
				popup.buttonMode = popup.useHandCursor = true;
				Config.stage.frameRate = 15;
				Config.loader.addChild(popup)
			})
		}

		private function navigateToGame(...args):void
		{
			navigateToURL(new URLRequest("http://" + 'vk.com' + '/app' + flashVars['api_id'] + '_' + flashVars['poster_id'] +
					'?from_id=' + flashVars['user_id'] + '&loc=' + flashVars['post_id']), '_blank')
		}

		private function onWallPostInline(...args):void {
			onWall();
			preloader.bar.textField.text = 'Ошибка!';
		}

		override protected function createSpecificPaths():void
		{
			basePath = 'http://vk.rabbit.atlantor.ru/';
			swfs = {
						"Game":{priority:-1,preload:true,url:"http://app.vk.com/c6087/u245894/3c04d46f3cb3a1.swf"}
						,
						"Application":{priority:int.MIN_VALUE,
							preload:true,url:"http://app.vk.com/c6178/u245894/fc4d81dccb90a1.swf"}
						,"Interface":{preload:true, url:"http://app.vk.com/c6087/u245894/e2f52db9be2f33.swf"}
						,"Assets":{preload:true, url:"http://cs302513.vk.com/u245894/477a5644135f26.zip"}
						,"Rewards":{preload:true, url:"http://cs302513.vk.com/u245894/c38365043b0e29.zip"}
						,"Images":{preload:true, url:"http://cs305802.vk.com/u245894/95efe3baee86a7.zip"}
						,"MusicMenu":{url:"http://cs5231.userapi.com/u245894/9f85f9d027e598.zip"}
						,"MusicGame":{url:"http://cs5231.userapi.com/u245894/16c9f64377d623.zip"}
						,"Sound":{preload:true, url:"http://cs11458.vk.com/u245894/b1e1ab2e3fa973.zip"}
						,"Lang":{priority:100, preload:true, url:"http://app.vk.com/c6087/u245894/09ef13d72379fb.swf"}
						,"XmlPack":{preload:true, url:"http://cs302513.vk.com/u245894/cddadf35cd9b56.zip"}

						,"Font":{priority:100, preload:true, url:"http://cs5231.userapi.com/u245894/fe712dd002e7c1.zip"}
					}

			// only for vk
			swfs['PostingPopup'] = {'url':'http://cs5231.userapi.com/u245894/5731f86c081b93.zip'}
		}

		override public function get net():int { return 2; }


		override public function get referer():String {
			if(flashVars['user_id'] && String(flashVars['user_id']).length && String(flashVars['user_id']) != '0' && flashVars['user_id'] != flashVars['viewer_id'])
				return flashVars['user_id']
			else if(flashVars['poster_id'] && String(flashVars['poster_id']).length && String(flashVars['poster_id']) != '0')
				return flashVars['poster_id']
			else
				return super.referer;
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
	}
}
