package {
	import com.somewater.rabbit.loader.StandaloneRabbitLoaderBase;
	import com.somewater.rabbit.net.LocalServerHandler;
	import com.somewater.rabbit.storage.Config;

	[Frame(factoryClass="com.somewater.rabbit.loader.EnPreloader")]
	[SWF(width="810", height="650", backgroundColor="#FFFFFF", frameRate="30")]
	public class FGLRabbitLoader extends StandaloneRabbitLoaderBase{

		[Embed(source='assets/images/sponsor.png')]
		private const SPONSOR_LOGO:Class;

		include 'com/somewater/rabbit/include/EnPreloaderAsset.as';

		public function FGLRabbitLoader(preloader:*) {
			this.preloader = preloader;
			super();
			Config.memory['hideTop'] = true;
			Config.memory['portfolioMode'] = true;
		}

		override protected function netInitialize():void {
			onNetInitializeComplete();
		}

		override public function get net():int {
			return 10;
		}

		include 'com/somewater/rabbit/include/LocalServer.as';

		override public function getAppFriends():Array {
			return [];
		}

		override public function showInviteWindow():void {
			Config.application.message('This feature is available for game in social networks only')
		}

		override protected function get SponsorLogo():Class {
			return SPONSOR_LOGO;
		}
	}
}
