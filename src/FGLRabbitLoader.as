package {
	import com.somewater.rabbit.loader.StandaloneRabbitLoaderBase;

	[SWF(width="810", height="650", backgroundColor="#FFFFFF", frameRate="30")]
	public class FGLRabbitLoader extends StandaloneRabbitLoaderBase{

		[Embed(source='../bin-debug/RabbitGame.swf', mimeType="application/octet-stream")]
		private const Game:Class;

		[Embed(source='../bin-debug/RabbitApplication.swf', mimeType="application/octet-stream")]
		private const Application:Class;

		[Embed(source='../bin-debug/assets/interface.swf', mimeType="application/octet-stream")]
		private const Interface:Class;

		[Embed(source='../bin-debug/assets/rabbit_asset.swf', mimeType="application/octet-stream")]
		private const Assets:Class;

		[Embed(source='../bin-debug/assets/rabbit_reward.swf', mimeType="application/octet-stream")]
		private const Rewards:Class;

		[Embed(source='../bin-debug/assets/rabbit_images.swf', mimeType="application/octet-stream")]
		private const Images:Class;

		[Embed(source='../bin-debug/assets/music_menu.swf', mimeType="application/octet-stream")]
		private const MusicMenu:Class;

		[Embed(source='../bin-debug/assets/music_game.swf', mimeType="application/octet-stream")]
		private const MusicGame:Class;

		[Embed(source='../bin-debug/assets/rabbit_sound.swf', mimeType="application/octet-stream")]
		private const Sound:Class;

		[Embed(source='../bin-debug/lang_ru.swf', mimeType="application/octet-stream")]
		private const Lang:Class;

		[Embed(source='../bin-debug/assets/fonts_ru.swf', mimeType="application/octet-stream")]
		private const Font:Class;

		public function FGLRabbitLoader() {
		}

		override protected function netInitialize():void {
			onNetInitializeComplete();
		}

		override protected function onNetInitializeComplete(... args):void {
			// сперва раздекодить все флешки
			standaloneFilesQueue.push(
				 {name:'Game', data:Game}
				,{name:'Application', data:Application}
				,{name:'Interface', data:Interface}
				,{name:'Assets', data:Assets}
				,{name:'Rewards', data:Rewards}
				,{name:'Images', data:Images}
				,{name:'MusicMenu', data:MusicMenu}
				,{name:'MusicGame', data:MusicGame}
				,{name:'Sound', data:Sound}
				,{name:'Lang', data:Lang}
				,{name:'Font', data:Font}
			);
			startDecoding(startOnNetInitializeCompleteImmediately);
		}

		private function startOnNetInitializeCompleteImmediately(...args):void
		{
			super.onNetInitializeComplete(args);
		}

		override public function get net():int {
			return 1;
		}
	}
}
