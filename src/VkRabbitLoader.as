package {
	import adapp.AdAppUtil;

	import clickozavr.Clickozavr;
	import clickozavr.ClickozavrEvent;
	import clickozavr.ContainerInfo;

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

		private var _clickozavr:Clickozavr;

		//[Embed(source="krolik_jo.jpg")]
		//private var livecardsAd:Class;

		include 'com/somewater/rabbit/include/RuPreloaderAsset.as';

		public function VkRabbitLoader() {
			super();
			Config.memory['autoPostLevelPass'] = false;
		}

		override protected function createLayers():void {
			super.createLayers();

			//_content.y= _popups.y = _tutorial.y = _tooltips.y = _cursors.y = 150;
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

			/*adLayer.graphics.beginFill(0xFFFFFF);
			adLayer.graphics.drawRect(0,0,Config.WIDTH, 150);
			adLayer.graphics.drawRect(0, 150 + Config.HEIGHT, Config.WIDTH, 100)

			_clickozavr = new Clickozavr('637', Config.WIDTH , Config.HEIGHT, adLayer);
			_clickozavr.addEventListener(ClickozavrEvent.GET_USER_DATA, onClickozavrCanGetUserData);
			_clickozavr.init([
			new ContainerInfo(ContainerInfo.WIDE600x150_BAR, (Config.WIDTH - 600) * 0.5, 0)], true);*/

			//var image:DisplayObject = new livecardsAd();// 120 x 800
			//image.x = 800;
			//adLayer.addChild(image);

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

			/*Security.allowDomain('*');
			var adappLoader:Loader = new Loader();
			adappLoader.contentLoaderInfo.addEventListener(Event.COMPLETE, onAdAppComplete);
			adappLoader.contentLoaderInfo.addEventListener(SecurityErrorEvent.SECURITY_ERROR, trace);
			adappLoader.load(new URLRequest('http://adapp.ru/ad_728x90.swf?platform_id=' + '370'),
					new LoaderContext(true, ApplicationDomain.currentDomain, SecurityDomain.currentDomain))*/

			super.onNetInitializeComplete();

			/*var livecardAdLoader:Loader = new Loader();
			livecardAdLoader.contentLoaderInfo.addEventListener(Event.COMPLETE, function(event:Event):void{
				var banner:Sprite = LoaderInfo(event.target).content as Sprite;
				banner.buttonMode =banner.useHandCursor = true;
				banner.y = 800;
				banner.addEventListener(MouseEvent.CLICK, onLivecardAdClick);
				var sh:Sprite = new Sprite();
				sh.graphics.beginFill(0,0)
				sh.graphics.drawRect(0,0,810,150);
				banner.addChild(sh)
				Config.loader.addChild(banner);
			})
			livecardAdLoader.load(new URLRequest(swfs['LivecardAd'].url), new LoaderContext(true, ApplicationDomain.currentDomain, SecurityDomain.currentDomain))
			*/
		}

		private function onLivecardAdClick(event:MouseEvent):void {
			trace('Livecards click');
			navigateToURL(new URLRequest('http://vk.com/app1860789'), '_blank');
			Config.stat(Stat.LIVECARD_AD);
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

		private function onWallPostInline(flashVars:Object):void {
			onWall();
			preloader.bar.textField.text = 'Ошибка!';
		}

		override protected function createSpecificPaths():void
		{
			basePath = 'http://rabbit.asflash.ru/';
			swfs = {
						"Game":{priority:-1,preload:true,url:"http://cs305802.vk.com/u245894/c0342f4f128ff6.zip"}
						,
						"Application":{priority:int.MIN_VALUE,
							preload:true,url:"http://cs305802.vk.com/u245894/bb198e1241b943.zip"}
						,"Interface":{preload:true, url:"http://cs305802.vk.com/u245894/83ec55adf88410.zip"}
						,"Assets":{preload:true, url:"http://cs305802.vk.com/u245894/bd7524baebc614.zip"}
						,"Rewards":{preload:true, url:"http://cs301110.vk.com/u245894/8a12bef99da591.zip"}
						,"Images":{preload:true, url:"http://cs305802.vk.com/u245894/95efe3baee86a7.zip"}
						,"MusicMenu":{url:"http://cs5231.userapi.com/u245894/9f85f9d027e598.zip"}
						,"MusicGame":{url:"http://cs5231.userapi.com/u245894/16c9f64377d623.zip"}
						,"Sound":{url:"http://cs5231.userapi.com/u245894/af59e6c026863d.zip"}
						,"Lang":{priority:100, preload:true, url:"http://cs305802.vk.com/u245894/d8358c76ac5e74.zip"}
						,"XmlPack":{preload:true, url:"http://cs305802.vk.com/u245894/8ec9ca036c8285.zip"}

						,"Font":{priority:100, preload:true, url:"http://cs5231.userapi.com/u245894/fe712dd002e7c1.zip"}
					}

			// only for vk
			swfs['PostingPopup'] = {'url':'http://cs5231.userapi.com/u245894/5731f86c081b93.zip'}
			swfs['LivecardAd'] = {'url':'http://cs11130.vk.com/u245894/9ad55940de39f8.zip'}
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
				_customHash['GAME_TESTERS']="Olesya Kazimirova;vk.com/olesya.kazimirova,Савелий Ташлыков;http://vk.com/id116118631,Лилия Беляева;vk.com/id139801679,Аркадий Клюкин;vk.com/id96381901,Ruslana Ruslana;vk.com/id78387355,Флора Шарыпова;vk.com/id132072432,София Попова;vk.com/id136765327,Дмитрий Новиков;vk.com/id150662339"
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
