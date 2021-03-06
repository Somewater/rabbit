package {
	import clickozavr.Clickozavr;

	import com.somewater.arrow.ArrowMailru;

	import com.somewater.net.SWFDecoderWrapper;
	import com.somewater.rabbit.loader.SocialRabbitLoader;
	import com.somewater.rabbit.storage.Config;
	import com.somewater.rabbit.storage.Lib;
	import com.somewater.social.SocialUser;
	import com.somewater.text.EmbededTextField;

	import flash.display.DisplayObject;
	import flash.display.LoaderInfo;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.net.URLRequest;
	import flash.net.navigateToURL;
	import flash.text.TextField;

	[SWF(width="720", height="680", backgroundColor="#FFFFFF", frameRate="30")]
	public class MailruRabbitLoader extends SocialRabbitLoader{

		include 'com/somewater/rabbit/include/RuPreloaderAsset.as';

		public function MailruRabbitLoader() {
			Config.WIDTH = 720;
			Config.HEIGHT = 650;
			Config.memory['autoPostLevelPass'] = true;
		}

		override protected function createLayers():void {
			super.createLayers();

			_content.y= _popups.y = _tooltips.y = _cursors.y = 0;
		}

		override protected function netInitialize():void
		{
			arrow = new ArrowMailru();
			onArrowComplete('3bc7d481082d5f4ac4e46e742ea9858f');
		}
		override protected function createSpecificPaths():void
		{
			basePath = 'http://mm.rabbit.atlantor.ru/';
			swfs = {
						"Game":{priority:-1,preload:true,url:"http://cdn9.appsmail.ru/hosting/666052/RabbitGame.swf?cb=8"}
						,
						"Application":{priority:int.MIN_VALUE,
							preload:true,url:"http://cdn0.appsmail.ru/hosting/666052/RabbitApplication.swf?cb=8.1"}
						,"Interface":{preload:true, url:"http://cdn6.appsmail.ru/hosting/666052/interface.swf?cb=8.1"}
						,"LevelMap":{preload:true, url:"http://cdn6.appsmail.ru/hosting/666052/level_map.swf"}
						,"Assets":{preload:true, url:"http://cdn6.appsmail.ru/hosting/666052/rabbit_asset.swf?cb=8"}
						,"Rewards":{preload:true, url:"http://cdn9.appsmail.ru/hosting/666052/rabbit_reward.swf?cb=8"}
						,"Images":{preload:true, url:"http://cdn1.appsmail.ru/hosting/666052/rabbit_images.swf?cb=6"}
						,"MusicMenu":{url:"http://cdn2.appsmail.ru/hosting/666052/music_menu.swf"}
						,"MusicGame":{url:"http://cdn5.appsmail.ru/hosting/666052/music_game.swf"}
						,"Sound":{preload:true, url:"http://cdn6.appsmail.ru/hosting/666052/rabbit_sound.swf?cb=7"}
						,"Lang":{priority:100, preload:true, url:"http://cdn4.appsmail.ru/hosting/666052/lang_pack.swf?cb=8"}
						,"XmlPack":{preload:true, url:"http://cdn8.appsmail.ru/hosting/666052/xml_pack.swf?cb=8"}

						,"Font":{priority:100, preload:true, url:"http://cdn9.appsmail.ru/hosting/666052/fonts_ru.swf"}
					}

			// only for mail.ru
			var i:int = 0;
			for (i = 0; i <= 31;i++)
				filePaths['level_pass_posting_' + i] = 'http://cdn0.appsmail.ru/hosting/666052/level_' + i + '.jpg';
			for (i = 0; i <= 79;i++)
				filePaths['reward_posting_' + i] = 'http://cdn7.appsmail.ru/hosting/666052/reward_' + i + '.jpg';
			filePaths['friends_invite_posting'] = 'http://cdn7.appsmail.ru/hosting/666052/friends_invite_posting.jpg';
		}

		override public function get net():int { return 3; }


		override public function get referer():String {
			if(flashVars['referer_id'] && String(flashVars['referer_id']).length && String(flashVars['referer_id']) != '0')
				return flashVars['referer_id']
			else
				return super.referer;
		}

		override public function posting(user:SocialUser = null, title:String = null, message:String = null, image:* = null, imageUrl:String = null, data:String = null, onComplete:Function = null, onError:Function = null, additionParams:Object = null):void {
			if(additionParams == null) additionParams = {};
			additionParams['linkText'] = Config.application.translate('POSTING_PLAY_BUTTON');
			if(data)
			{
				var dataObj:Object = {}
				try{dataObj = serverHandler.fromJson(data);}catch(err:Error){}
				data = '';
				for (var key:String in dataObj)
					data += (data.length ? ';' : '') + key + ':' + dataObj[key]
			}
			arrow.posting(user, title, message, image, imageUrl, data, onComplete, onError, additionParams);
		}


		override public function clear():void {
			super.clear();

			adLayer.graphics.beginFill(0xFFFFFF);
			adLayer.graphics.drawRect(0,650,720, 30);
			var grouplink:EmbededTextField = new EmbededTextField(Config.FONT_SECONDARY, 0x31B1E8, 12, true);
			grouplink.mouseEnabled = true;
			grouplink.underline = true;
			grouplink.htmlText = '<a href="event:">Официальная группа игры "Кроль"</a>';
			grouplink.addEventListener(MouseEvent.CLICK, onGrouplInkClicked);
			grouplink.x = (Config.WIDTH - grouplink.width) * 0.5;
			grouplink.y = 660;
			adLayer.addChild(grouplink);
		}

		private function onGrouplInkClicked(event:MouseEvent):void {
			navigateToURL(new URLRequest('http://my.mail.ru/community/krolgame/'), '_blank');
		}

		override public function get hasNavigateToHomepage():Boolean {
			return true;
		}

		override public function get hasPaymentApi():Boolean {
			return false;
		}
	}
}
