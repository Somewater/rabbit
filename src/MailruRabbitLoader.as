package {
	import clickozavr.Clickozavr;

	import com.somewater.net.SWFDecoderWrapper;
	import com.somewater.rabbit.loader.SocialRabbitLoader;
	import com.somewater.rabbit.storage.Config;
	import com.somewater.rabbit.storage.Lib;
	import com.somewater.social.SocialUser;

	import flash.display.DisplayObject;
	import flash.display.LoaderInfo;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.net.URLRequest;
	import flash.net.navigateToURL;

	[SWF(width="720", height="650", backgroundColor="#FFFFFF", frameRate="30")]
	public class MailruRabbitLoader extends SocialRabbitLoader{

		public function MailruRabbitLoader() {
			Config.WIDTH = 720;
			Config.HEIGHT = 650;
		}

		override protected function createLayers():void {
			super.createLayers();

			_content.y= _popups.y = _tooltips.y = _cursors.y = 0;
		}

		override protected function netInitialize():void
		{
			arrow = ArrowMailFactory.create;
			SWFDecoderWrapper.load(arrow, function(_arr:DisplayObject):void{
				arrow = _arr;
				arrow.createSocial();
				onArrowComplete('3bc7d481082d5f4ac4e46e742ea9858f');
			}, function(...args):void{
				trace('ERROR ARROW PARSING ' + args);
			})
		}
		override protected function createSpecificPaths():void
		{
			basePath = 'http://rabbit.asflash.ru/';
			swfs = {
						"Game":{priority:-1,preload:true,url:"http://cdn9.appsmail.ru/hosting/666052/RabbitGame.swf"}
						,
						"Application":{priority:int.MIN_VALUE,
							preload:true,url:"http://cdn0.appsmail.ru/hosting/666052/RabbitApplication.swf"}
						,"Interface":{preload:true, url:"http://cdn6.appsmail.ru/hosting/666052/interface.swf"}
						,"Assets":{preload:true, url:"http://cdn6.appsmail.ru/hosting/666052/rabbit_asset.swf"}
						,"Rewards":{preload:true, url:"http://cdn9.appsmail.ru/hosting/666052/rabbit_reward.swf"}
						,"Images":{preload:true, url:"http://cdn1.appsmail.ru/hosting/666052/rabbit_images.swf"}
						,"MusicMenu":{url:"http://cdn2.appsmail.ru/hosting/666052/music_menu.swf"}
						,"MusicGame":{url:"http://cdn5.appsmail.ru/hosting/666052/music_game.swf"}
						,"Sound":{url:"http://cdn6.appsmail.ru/hosting/666052/rabbit_sound.swf"}
						,"Lang":{priority:100, preload:true, url:"http://cdn4.appsmail.ru/hosting/666052/lang_ru.swf"}
						,"XmlPack":{preload:true, url:"http://cdn8.appsmail.ru/hosting/666052/xml_pack.swf"}

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
	}
}
