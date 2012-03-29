package {
	import com.somewater.rabbit.loader.StandaloneRabbitLoaderBase;
	import com.somewater.rabbit.net.LocalServerHandler;
	import com.somewater.rabbit.storage.Config;

	[Frame(factoryClass="com.somewater.rabbit.loader.Preloader")]
	[SWF(width="810", height="650", backgroundColor="#FFFFFF", frameRate="30")]
	public class FGLRabbitLoader extends StandaloneRabbitLoaderBase{

		public function FGLRabbitLoader(preloader:*) {
			this.preloader = preloader;
			super();
			Config.memory['hideTop'] = true;

			// первый пункт должен занимать намного больше, чем остальные, т.к. производится энкодинг флешек
			// стартуем не со значения 0, а с 0.7, т.к. прелоадер доходит до 70%, когда файл загружен
			progressStepsByType = [0.7, 0.95, 0.97, 0.99, 1];
		}

		override protected function netInitialize():void {
			onNetInitializeComplete();
		}

		override public function get net():int {
			return 10;
		}

		include 'com/somewater/rabbit/include/LocalServer.as';
	}
}
