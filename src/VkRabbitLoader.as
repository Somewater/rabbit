package {
	import com.somewater.net.SWFDecoderWrapper;
	import com.somewater.rabbit.loader.SocialRabbitLoader;

	import flash.display.DisplayObject;
	import flash.events.MouseEvent;
	import flash.net.URLRequest;
	import flash.net.navigateToURL;

	[SWF(width="810", height="650", backgroundColor="#FFFFFF", frameRate="30")]
	public class VkRabbitLoader extends SocialRabbitLoader{
		public function VkRabbitLoader() {
		}

		override protected function netInitialize():void
		{
			arrow = ArrowVKLCFactory.create;
			SWFDecoderWrapper.load(arrow, function(_arr:DisplayObject):void{
				arrow = _arr;
				arrow.createSocial();
				arrow.data.onWallPostInline = onWallPostInline;
				arrow.data.onWallViewInline = onWallViewInline;
				onArrowComplete('hjli32ls');
			}, function(...args):void{
				trace('ERROR ARROW PARSING ' + args);
			})
		}

		private function onWall():void
		{
			preloader.x += 100;
			preloader.y += 80;
		}

		private function onWallViewInline(flashVars:Object):void {
			onWall();
			preloader.bar.textField.text = 'Играть!';
			preloader.bar.textField.mouseEnabled = false;
			preloader.bar.useHandCursor = preloader.bar.buttonMode = true;
			stage.addEventListener(MouseEvent.MOUSE_DOWN, function(e:MouseEvent):void{
				navigateToURL(new URLRequest("http://" + flashVars['domain'] + '/app' + flashVars['api_id'] + '_' + flashVars['poster_id'] +
				'?from_id=' + flashVars['user_id'] + '&loc=' + flashVars['post_id']), '_blank')
			})
		}

		private function onWallPostInline(flashVars:Object):void {
			onWall();
			preloader.bar.textField.text = 'Ошибка!';
		}

		override protected function createSpecificPaths():void
		{
			basePath = 'http://rabbit.asflash.ru/';
			swfs = {
						"Game":{priority:-1,preload:true,url:"RabbitGame.swf"}
						,
						"Application":{priority:int.MIN_VALUE,
							preload:true,url:"RabbitApplication.swf"}
						,"Interface":{preload:true, url:"assets/interface.swf"}
						,"Assets":{preload:true, url:"assets/rabbit_asset.swf"}
						,"Rewards":{preload:true, url:"assets/rabbit_reward.swf"}
						,"Images":{preload:true, url:"assets/rabbit_images.swf"}
						,"MusicMenu":{url:"assets/music_menu.swf"}
						,"MusicGame":{url:"assets/music_game.swf"}
						,"Lang":{priority:100, preload:true, url:"lang_ru.swf"}
						,"XmlPack":{preload:true, url:"xml_pack.swf"}

						,"Font":{priority:100, preload:true, url:"assets/fonts_ru.swf"}
						//,"Font":{priority:1000, preload:true, url:"assets/fonts_ru.swf"}
					}

			filePaths = {
							 "Levels":"levels.xml"
							,"Managers":"Managers.xml"
							,"Description":"Description.xml"
							,"Rewards":"Rewards.xml"
						}
		}

		override public function get net():int { return 2; }


		override public function get referer():String {
			if(flashVars['user_id'] && String(flashVars['user_id']).length && String(flashVars['user_id']) != '0')
				return flashVars['user_id']
			else if(flashVars['poster_id'] && String(flashVars['poster_id']).length && String(flashVars['poster_id']) != '0')
				return flashVars['poster_id']
			else
				return super.referer;
		}
	}
}
