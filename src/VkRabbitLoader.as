package {
	import adapp.AdAppUtil;

	import clickozavr.Clickozavr;
	import clickozavr.ClickozavrEvent;
	import clickozavr.ContainerInfo;

	import com.somewater.arrow.ArrowVkcom;

	import com.somewater.net.SWFDecoderWrapper;
	import com.somewater.rabbit.Stat;
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


	[SWF(width="810", height="650", backgroundColor="#FFFFFF", frameRate="30")]
	public class VkRabbitLoader extends SocialRabbitLoader{

		include 'com/somewater/rabbit/include/RuPreloaderAsset.as';

		public function VkRabbitLoader() {
			super();
			Config.memory['autoPostLevelPass'] = false;
		}

		override protected function netInitialize():void
		{
			arrow = new ArrowVkcom();
			arrow.addEventListener('wall_view_inline',onWallViewInline);
			arrow.addEventListener('wall_post_inline',onWallPostInline);
			onArrowComplete('hjli32ls');
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
						"Game":{priority:-1,preload:true,url:""}
						,
						"Application":{priority:int.MIN_VALUE,
							preload:true,url:""}
						,"Interface":{preload:true, url:""}
						,"Assets":{preload:true, url:"http://cs302513.vk.com/u245894/477a5644135f26.zip"}
						,"Rewards":{preload:true, url:"http://cs302513.vk.com/u245894/c38365043b0e29.zip"}
						,"Images":{preload:true, url:"http://cs305802.vk.com/u245894/95efe3baee86a7.zip"}
						,"MusicMenu":{url:"http://cs5231.userapi.com/u245894/9f85f9d027e598.zip"}
						,"MusicGame":{url:"http://cs5231.userapi.com/u245894/16c9f64377d623.zip"}
						,"Sound":{preload:true, url:"http://cs11458.vk.com/u245894/b1e1ab2e3fa973.zip"}
						,"Lang":{priority:100, preload:true, url:""}
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
			navigateToURL(new URLRequest("http://" + 'vk.com' + '/id' + userId), '_blank');
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
