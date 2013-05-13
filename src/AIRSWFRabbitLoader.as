package {
	import com.pblabs.engine.debug.Stats;
	import com.somewater.rabbit.IRabbitApplication;
	import com.somewater.rabbit.loader.StandaloneRabbitLoaderBase;
	import com.somewater.rabbit.net.LocalServerHandler;
	import com.somewater.rabbit.storage.Config;

	import flash.display.DisplayObject;
	import flash.display.Graphics;
	import flash.display.Sprite;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;

	import flash.events.Event;
	import flash.system.Capabilities;
	import flash.utils.getDefinitionByName;

	[Frame(factoryClass="com.somewater.rabbit.loader.EnPreloader")]
	[SWF(width="810", height="650", backgroundColor="#FFFFFF", frameRate="30")]
	public class AIRSWFRabbitLoader extends StandaloneRabbitLoaderBase{

		include 'com/somewater/rabbit/include/EnPreloaderAsset.as';
		
		private var customPreloader:*;
		override public function getPreloader():* {
			return customPreloader;
		}

		public function AIRSWFRabbitLoader(preloader:*) {
			this.customPreloader = preloader;
			super();
			Config.memory['hideTop'] = true;
			Config.memory['portfolioMode'] = true;
		}


		override protected function configurateStage():void {
			stage.align = StageAlign.TOP_LEFT;
			stage.scaleMode = StageScaleMode.NO_SCALE;

			var sw:int = stage.stageWidth
			var sh:int = stage.stageHeight

			Config.WIDTH = Math.min(12,int(sw / Config.TILE_WIDTH)) * Config.TILE_WIDTH;
			Config.HEIGHT = Math.min(14,int(sh / Config.TILE_HEIGHT)) * Config.TILE_HEIGHT;

			var x:int = this.x = int((sw - Config.WIDTH) * 0.5);
			var y:int = this.y = int((sh - Config.HEIGHT) * 0.5);
			// также создаем экран, чтобы не видеть что делается вне прямоугольника игры
			if(x > 0 || y > 0)
			{
				var g:Graphics = (stage.addChild(new Sprite()) as Sprite).graphics;
				g.beginFill(0);
				if(x > 0)
				{
					g.drawRect(0, y, x, Config.HEIGHT);
					g.drawRect(x + Config.WIDTH, y, x, Config.HEIGHT);
				}
				if(y > 0)
				{
					g.drawRect(0, 0, x * 2 + Config.WIDTH, y);
					g.drawRect(0, y + Config.HEIGHT, x * 2 + Config.WIDTH, y);
				}
			}
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
