package {
	import com.somewater.rabbit.loader.StandaloneRabbitLoaderBase;
	import com.somewater.rabbit.net.LocalServerHandler;
	import com.somewater.rabbit.storage.Config;

	[SWF(width="810", height="650", backgroundColor="#FFFFFF", frameRate="30")]
	public class FGLRabbitLoader extends StandaloneRabbitLoaderBase{

		public function FGLRabbitLoader() {
			Config.memory['hideTop'] = true;
		}

		override protected function netInitialize():void {
			onNetInitializeComplete();
		}

		override public function get net():int {
			return 1;
		}

		include 'com/somewater/rabbit/include/LocalServer.as';
	}
}
