package {
	import adapp.AdAppUtil;

	import clickozavr.Clickozavr;
	import clickozavr.ClickozavrEvent;
	import clickozavr.ContainerInfo;

	import com.somewater.net.SWFDecoderWrapper;
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


	[SWF(width="810", height="900", backgroundColor="#FFFFFF", frameRate="30")]
	public class VkRabbitLoader extends SocialRabbitLoader{

		private var _clickozavr:Clickozavr;
		private var adLayer:Sprite;

		public function VkRabbitLoader() {
		}

		override protected function createLayers():void {
			super.createLayers();

			_content.y= _popups.y = _tooltips.y = _cursors.y = 150;
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
			//var bannerTape: BannerTape = new BannerTape("3298", "791", Config.WIDTH, 1);
			//stage.addChild(bannerTape);

			adLayer = new Sprite();
			adLayer.graphics.beginFill(0xFFFFFF);
			adLayer.graphics.drawRect(0,0,Config.WIDTH, 150);
			adLayer.graphics.drawRect(0, 150 + Config.HEIGHT, Config.WIDTH, 100)
			addChild(adLayer);

			_clickozavr = new Clickozavr('637', Config.WIDTH , Config.HEIGHT, adLayer);
			_clickozavr.addEventListener(ClickozavrEvent.GET_USER_DATA, onClickozavrCanGetUserData);
			_clickozavr.init([
			new ContainerInfo(ContainerInfo.WIDE600x150_BAR, (Config.WIDTH - 600) * 0.5, 0)], true);

//			var ads:AdAppUtil = new AdAppUtil('370', arrow.flashVars['api_id'], arrow.key,
//									 arrow.flashVars['api_url'], arrow.flashVars['viewer_id'], arrow.flashVars['secret']);
//
//			ads.getAds(onGetAds,"JSON",1);
//			if(data.user)
//			{
//				var ob1:Object = new Object;
//				ob1.nam = 'uid';
//				ob1.val = data.user.uid;
//				var ob2:Object = new Object;
//				ob2.nam = 'sex';
//				ob2.val = data.user.sex;
//				var ob3:Object = new Object;
//				ob3.nam = 'bdate';
//				ob3.val = data.user.bdate;
//				var ob4:Object = new Object;
//				ob4.nam = 'city';
//				ob4.val = data.user.city;
//				var ob5:Object = new Object;
//				ob5.nam = 'country';
//				ob5.val = data.user.country;
//				var arr:Array = new Array(ob1, ob2, ob3, ob4, ob5);
//				adAppRequest(arr);
//			}
//			ads.handler_(null)
//
//			function onGetAds(evt:Event):void
//			{
//				trace(evt.currentTarget.data);
//			}

			Security.allowDomain('*');
			var adappLoader:Loader = new Loader();
			adappLoader.contentLoaderInfo.addEventListener(Event.COMPLETE, onAdAppComplete);
			adappLoader.contentLoaderInfo.addEventListener(SecurityErrorEvent.SECURITY_ERROR, trace);
			adappLoader.load(new URLRequest('http://adapp.ru/ad_728x90.swf?platform_id=' + '370'),
					new LoaderContext(true, ApplicationDomain.currentDomain, SecurityDomain.currentDomain))

			super.onNetInitializeComplete();
		}

		private function onAdAppComplete(event:Event):void {
			var banner:DisplayObject = LoaderInfo(event.currentTarget).content;
			banner.x = (Config.WIDTH - banner.width) * 0.5;
			banner.y = 150 + Config.HEIGHT;
			adLayer.addChild(banner);
		}

		private function onClickozavrCanGetUserData(event:Event):void {
			var u:SocialUser = getUser();
			var sex:String = u.male ? 'male' : 'female';

			var userData:XML = <userinfo id={u.id} sex={sex}></userinfo>;
			if(u.bdate)
			{
				var bdate:Date = new Date(u.bdate * 1000)
				userData.@birthday = bdate.date + '.' + (bdate.month + 1) + '.' + bdate.fullYear;
			}

			if(u.city || u.country)
			{
				var location:XML = <location></location>
				userData.appendChild(location);
				if(u.city)
					location.appendChild(<city id={u.cityCode} name={u.city}></city>);
				if(u.country)
					location.appendChild(<country id={u.countryCode} name={u.country}></country>);
			}
			_clickozavr.getUserData('2', '637', arrow.flashVars['api_id'], userData);
		}

		private function onWall():void
		{
			_content.y= _popups.y = _tooltips.y = _cursors.y = 0;//revert ads offset
			preloader.scaleX = preloader.scaleY = 0.8;
			preloader.x += 0;
			preloader.y += -30;
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
							preload:true,url:"http://cs11081.vkontakte.ru/u245894/0cb3359a428ec6.zip"}
						,"Interface":{preload:true, url:"http://cs301105.vkontakte.ru/u245894/4cef321a434828.zip"}
						,"Assets":{preload:true, url:"http://cs301105.vkontakte.ru/u245894/20130588dba46b.zip"}
						,"Rewards":{preload:true, url:"http://cs305914.vkontakte.ru/u245894/484acef2b22ff3.zip"}
						,"Images":{preload:true, url:"http://cs301105.vkontakte.ru/u245894/bed3fdd7fef6d3.zip"}
						,"MusicMenu":{url:"http://cs301105.vkontakte.ru/u245894/8249c8fc1ffbf9.zip"}
						,"MusicGame":{url:"http://cs301105.vkontakte.ru/u245894/721ed8935f06d4.zip"}
						,"Sound":{url:"http://cs5392.vkontakte.ru/u245894/849e0bcdf7ff31.zip"}
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
			if(flashVars['user_id'] && String(flashVars['user_id']).length && String(flashVars['user_id']) != '0' && flashVars['user_id'] != flashVars['viewer_id'])
				return flashVars['user_id']
			else if(flashVars['poster_id'] && String(flashVars['poster_id']).length && String(flashVars['poster_id']) != '0')
				return flashVars['poster_id']
			else
				return super.referer;
		}
	}
}
