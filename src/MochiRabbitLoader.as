package {
	import com.somewater.rabbit.loader.StandaloneRabbitLoaderBase;
	import com.somewater.rabbit.net.LocalServerHandler;
	import com.somewater.rabbit.storage.Config;

import flash.display.LoaderInfo;

import mochi.as3.MochiAd;

	[SWF(width="810", height="650", backgroundColor="#FFFFFF", frameRate="30")]
	dynamic public class MochiRabbitLoader extends StandaloneRabbitLoaderBase{

		include 'com/somewater/rabbit/include/EnPreloaderAsset.as';

		private var customPreloader:*;
		override public function getPreloader():* {
			return customPreloader;
		}
		
		public function MochiRabbitLoader() {
			customPreloader = new PreloaderClass();
			for(var i:int = 0; i < 10; i++)
				customPreloader.bar["carrot" + i].stop();
			super();
		}

		override protected function netInitialize():void {
			var _mochiads_game_id:String = "99379abc8a663907";
			MochiAd.showPreGameAd({
				id: _mochiads_game_id,
				clip: this,
				res: stage.stageWidth + "x" + stage.stageHeight,
				ad_finished: onNetInitializeComplete
			});
		}

		override public function get net():int {
			return 50;
		}

		override public function get hasUserApi():Boolean
		{
			return true;
		}

		override public function get hasPaymentApi():Boolean
		{
			return true;
		}

		include 'com/somewater/rabbit/include/LocalServer.as';


		override public function get loaderInfo():LoaderInfo {
			if(!root || root == this)
				return super.loaderInfo;
			var loaderInfo:LoaderInfo = root.loaderInfo;
			if (loaderInfo.loader != null) {
				loaderInfo = loaderInfo.loader.loaderInfo;
			}
			return loaderInfo;
		}
}
}
