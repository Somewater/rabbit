package com.somewater.rabbit.loader {
	import com.somewater.net.SWFDecoderWrapper;
	import com.somewater.net.ServerHandler;
	import com.somewater.rabbit.net.LocalServerHandlerBase;
	import com.somewater.rabbit.storage.Config;
	import com.somewater.social.SocialUser;

	import flash.display.DisplayObject;
	import flash.events.Event;
	import flash.system.ApplicationDomain;

	/**
	 * Прелоадер с эмбедом всех необходимых файлов внутрь себя
	 */
	public class StandaloneRabbitLoaderBase extends RabbitLoaderBase{

		[Embed(source='../../../../../bin-debug/RabbitGame.swf', mimeType="application/octet-stream")]
		private const Game:Class;

		[Embed(source='../../../../../bin-debug/RabbitApplication.swf', mimeType="application/octet-stream")]
		private const Application:Class;

		[Embed(source='../../../../../bin-debug/assets/interface.swf', mimeType="application/octet-stream")]
		private const Interface:Class;

		[Embed(source='../../../../../bin-debug/assets/rabbit_asset.swf', mimeType="application/octet-stream")]
		private const Assets:Class;

		[Embed(source='../../../../../bin-debug/assets/rabbit_reward.swf', mimeType="application/octet-stream")]
		private const Rewards:Class;

		[Embed(source='../../../../../bin-debug/assets/rabbit_images.swf', mimeType="application/octet-stream")]
		private const Images:Class;

		[Embed(source='../../../../../bin-debug/assets/music_menu.swf', mimeType="application/octet-stream")]
		private const MusicMenu:Class;

		[Embed(source='../../../../../bin-debug/assets/music_game.swf', mimeType="application/octet-stream")]
		private const MusicGame:Class;

		[Embed(source='../../../../../bin-debug/assets/rabbit_sound.swf', mimeType="application/octet-stream")]
		private const Sound:Class;

		[Embed(source='../../../../../tmp/tmp_lang_pack.swf', mimeType="application/octet-stream")]
		private const Lang:Class;

		[Embed(source='../../../../../bin-debug/xml_pack.swf', mimeType="application/octet-stream")]
		private const XmlPack:Class;

		[Embed(source='../../../../../tmp/tmp_config_pack.swf', mimeType="application/octet-stream")]
		private const ConfigPack:Class;

		[Embed(source='../../../../../bin-debug/assets/fonts_ru.swf', mimeType="application/octet-stream")]
		private const Font:Class;

		/**
		 * Сколько файлов находится в процессе энкодинга либо прочих действий,
		 * не позволяющих воспользоватьсяих контнетом в данный момент
		 */
		private var standaloneFilesInProcess:int = 0;

		/**
		 * Помещаем сюда файлы на обработку в формате
		 * {name:'RabbitGame', data:Class}
		 */
		protected var standaloneFilesQueue:Array = [];
		private var maxStandaloneFilesQueue:int;

		private var startDecodingCallback:Function;

		public function StandaloneRabbitLoaderBase() {
			super();

			if(swfs == null)
				swfs = {};

			// первый пункт должен занимать намного больше, чем остальные, т.к. производится энкодинг флешек
			// стартуем не со значения 0, а с 0.7, т.к. прелоадер доходит до 70%, когда файл загружен
			progressStepsByType = [0.7, 0.95, 0.97, 0.99, 1];
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
				,{name:'XmlPack', data:XmlPack}
				,{name:'ConfigPack', data:ConfigPack}
				,{name:'Font', data:Font}
			);
			startDecoding(startOnNetInitializeCompleteImmediately);
		}

		private function startOnNetInitializeCompleteImmediately(...args):void
		{
			super.onNetInitializeComplete(args);
		}


		override protected function createSpecificPaths():void {
			// nothing
		}

		protected function startDecoding(onComplete:Function):void
		{
			if(startDecodingCallback != null)
				throw new Error('Only one thread');
			startDecodingCallback = onComplete;
			maxStandaloneFilesQueue = standaloneFilesQueue.length;
			addEventListener(Event.ENTER_FRAME, onDecodeEnterFrame);
		}

		private function onDecodeEnterFrame(event:Event):void {
			if(standaloneFilesInProcess == 0)
			{
				setProgress(0, (maxStandaloneFilesQueue - standaloneFilesQueue.length) / maxStandaloneFilesQueue)
				if(standaloneFilesQueue.length)
				{
					var fileData:Object = standaloneFilesQueue.pop();
					addStandaloneFile(fileData.name,  fileData.data);
				}
				else
				{
					var f:Function = startDecodingCallback;
					startDecodingCallback = null;
					removeEventListener(Event.ENTER_FRAME, onDecodeEnterFrame);
					f();

				}
			}
		}

		/**
		 * Добавить в хранилище файл
		 * @param name
		 * @param data класс, создающий ByteArray (возможно требующий енкодинга)
		 */
		protected function addStandaloneFile(name:String, data:Class):void
		{
			if(swfs[name] && swfs[name].loaded)
				throw new Error('File "' + name + '" already added in standalone library');

			standaloneFilesInProcess += 1;
			SWFDecoderWrapper.load(new data(), function(decodedDO:*):void{
				if(decodedDO == null) throw new Error('WTF', 1034);
				addDecodedFile(name, decodedDO);
				trace("[STANDALONE DECODING COMPLETE] filename " + name);
				standaloneFilesInProcess -= 1;
			}, function():void{
				CONFIG::debug
				{
					trace('[STANDALONE DECODING ERROR] filename ' + name);
				}
			});
		}

		/**
		 * Добавить разэнкоженный файл
		 */
		protected function addDecodedFile(name:String, content:DisplayObject):void
		{
			swfADs[name] = content.loaderInfo.applicationDomain || ApplicationDomain.currentDomain;
			if(swfs[name] == null)
				swfs[name] = {};
			swfs[name].loaded = true;
		}

		protected function getConfigForServerHandler():Object
		{
			return {
				'init_user':{
								items:"200:2,201:1,202:1,203:1"
								,money: 9999
							}
			}
		}


		override public function getClassByName(resourceName:String):Class {
			if(resourceName == 'interface.SponsorLogo')
				return SponsorLogo;
			else
				return super.getClassByName(resourceName);
		}

		protected function get SponsorLogo():Class {
			return null;
		}
	}
}
