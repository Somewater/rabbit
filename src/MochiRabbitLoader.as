package {
	import com.somewater.rabbit.loader.StandaloneRabbitLoaderBase;
	import com.somewater.rabbit.net.LocalServerHandler;
	import com.somewater.rabbit.storage.Config;

	import flash.display.LoaderInfo;
	
	import mochi.as3.MochiAd;
	import mochi.as3.MochiScores;
	import mochi.as3.MochiServices;

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
			
			Config.memory['showTopButton'] = true;
			Config.memory['customTop'] = customTop;
		}

		override protected function netInitialize():void {
			var _mochiads_game_id:String = "99379abc8a663907";
			var root:* = this.root;
			MochiAd.showPreGameAd({
				id: _mochiads_game_id,
				clip: this,
				res: stage.stageWidth + "x" + stage.stageHeight,
				ad_finished: function():void{
					MochiServices.connect(_mochiads_game_id, root, function(error:String = 'undefined'){
						if(Config.application)
							Config.application.fatalError(error);
					});
					onNetInitializeComplete();
				}
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

		include 'com/somewater/rabbit/include/MochiServer.as';


		override public function get loaderInfo():LoaderInfo {
			if(!root || root == this)
				return super.loaderInfo;
			var loaderInfo:LoaderInfo = root.loaderInfo;
			if (loaderInfo.loader != null) {
				loaderInfo = loaderInfo.loader.loaderInfo;
			}
			return loaderInfo;
		}
	
		private function customTop(user:Object/** @see com.somewater.rabbit.storage.UserProfile */):void {
			var o:Object = { n: [15, 6, 8, 15, 6, 10, 1, 15, 2, 8, 5, 2, 5, 4, 6, 15], f: function (i:Number,s:String):String { if (s.length == 16) return s; return this.f(i+1,s + this.n[i].toString(16));}};
			var boardID:String = o.f(0,"");
			MochiScores.showLeaderboard({boardID: boardID});
		}
}
}
