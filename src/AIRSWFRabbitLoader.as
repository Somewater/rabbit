package {
	import com.pblabs.engine.debug.Stats;
	import com.somewater.rabbit.IRabbitApplication;
	import com.somewater.rabbit.loader.StandaloneRabbitLoaderBase;
	import com.somewater.rabbit.net.LocalServerHandler;
	import com.somewater.rabbit.storage.Config;

	import flash.display.DisplayObject;

	import flash.events.Event;
	import flash.utils.getDefinitionByName;

	[Frame(factoryClass="com.somewater.rabbit.loader.EnPreloader")]
	[SWF(width="810", height="650", backgroundColor="#FFFFFF", frameRate="30")]
	public class AIRSWFRabbitLoader extends StandaloneRabbitLoaderBase{

		include 'com/somewater/rabbit/include/EnPreloaderAsset.as';

		public function AIRSWFRabbitLoader(preloader:*) {
			this.preloader = preloader;
			super();
			Config.memory['hideTop'] = true;
			Config.memory['portfolioMode'] = true;
		}


		override protected function createSpecificPaths():void {
			super.createSpecificPaths();
		}

		override protected function onAddedToStage(e:Event):void {
			//Config.WIDTH = stage.stageHeight;
			//Config.HEIGHT = stage.stageWidth;

			super.onAddedToStage(e);
			stage.addChild(new Stats());
		}

		override protected function netInitialize():void {
			onNetInitializeComplete();
		}

		override protected function onNetInitializeComplete(... args):void {
			super.onNetInitializeComplete(args);
		}

		override public function get net():int {
			return 20;
		}

		include 'com/somewater/rabbit/include/LocalServer.as';

		override public function getAppFriends():Array {
			return [];
		}

		override public function showInviteWindow():void {
			Config.application.message('This feature is available for game in social networks only')
		}
	}
}
