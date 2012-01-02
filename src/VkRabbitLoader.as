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
						"Game":{priority:-1,preload:true,url:"http://cs301105.vkontakte.ru/u245894/62276fad40b78d.zip"}
						,
						"Application":{priority:int.MIN_VALUE,
							preload:true,url:"http://cs301105.vkontakte.ru/u245894/c13b237283840e.zip"}
						,"Interface":{preload:true, url:"http://cs301105.vkontakte.ru/u245894/4cef321a434828.zip"}
						,"Assets":{preload:true, url:"http://cs301105.vkontakte.ru/u245894/20130588dba46b.zip"}
						,"Rewards":{preload:true, url:"http://cs301105.vkontakte.ru/u245894/4194d38dca2dae.zip"}
						,"Images":{preload:true, url:"http://cs301105.vkontakte.ru/u245894/bed3fdd7fef6d3.zip"}
						,"MusicMenu":{url:"http://cs301105.vkontakte.ru/u245894/8249c8fc1ffbf9.zip"}
						,"MusicGame":{url:"http://cs301105.vkontakte.ru/u245894/721ed8935f06d4.zip"}
						,"Lang":{priority:100, preload:true, url:"http://cs301105.vkontakte.ru/u245894/4fb4da77724f6a.zip"}
						,"XmlPack":{preload:true, url:"http://cs303308.vkontakte.ru/u245894/8400f1f792fde5.zip"}

						,"Font":{priority:100, preload:true, url:"http://cs301105.vkontakte.ru/u245894/e07afb77864e16.zip"}
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
