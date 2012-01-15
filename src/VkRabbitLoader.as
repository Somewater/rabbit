package {
	import com.somewater.net.SWFDecoderWrapper;
	import com.somewater.rabbit.loader.SocialRabbitLoader;
	import com.somewater.rabbit.storage.Config;
	import com.somewater.rabbit.storage.Lib;
	
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
		
		override protected function onNetInitializeComplete(...args):void
		{
			super.onNetInitializeComplete(args);
			
			trace('[FIX] ' + Lib.ASSETS); // быстрофикс от 6 янв.
			//var bannerTape: BannerTape = new BannerTape("3298", "791", Config.WIDTH, 1);
			//stage.addChild(bannerTape);
		}

		private function onWall():void
		{
			preloader.scaleX = preloader.scaleY = 0.8;
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
						"Game":{priority:-1,preload:true,url:"http://cs11081.vkontakte.ru/u245894/ed81ed8c9331f0.zip"}
						,
						"Application":{priority:int.MIN_VALUE,
							preload:true,url:"http://cs11081.vkontakte.ru/u245894/65ec47084ab029.zip"}
						,"Interface":{preload:true, url:"http://cs301105.vkontakte.ru/u245894/4cef321a434828.zip"}
						,"Assets":{preload:true, url:"http://cs301105.vkontakte.ru/u245894/20130588dba46b.zip"}
						,"Rewards":{preload:true, url:"http://cs305914.vkontakte.ru/u245894/484acef2b22ff3.zip"}
						,"Images":{preload:true, url:"http://cs301105.vkontakte.ru/u245894/bed3fdd7fef6d3.zip"}
						,"MusicMenu":{url:"http://cs301105.vkontakte.ru/u245894/8249c8fc1ffbf9.zip"}
						,"MusicGame":{url:"http://cs301105.vkontakte.ru/u245894/721ed8935f06d4.zip"}
						,"Lang":{priority:100, preload:true, url:"http://cs11081.vkontakte.ru/u245894/7f07018b2d3aca.zip"}
						,"XmlPack":{preload:true, url:"http://cs11081.vkontakte.ru/u245894/4e8fd0a591d890.zip"}

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
