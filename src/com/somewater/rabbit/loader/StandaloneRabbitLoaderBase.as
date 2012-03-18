package com.somewater.rabbit.loader {
	import com.somewater.net.SWFDecoderWrapper;

	import flash.display.DisplayObject;
	import flash.system.ApplicationDomain;

	/**
	 * Прелоадер с эмбедом всех необходимых файлов внутрь себя
	 */
	public class StandaloneRabbitLoaderBase extends RabbitLoaderBase{

		/**
		 * Сколько файлов находится в процессе энкодинга либо прочих действий,
		 * не позволяющих воспользоватьсяих контнетом в данный момент
		 */
		private var standaloneFilesInProcess:int = 0;

		public function StandaloneRabbitLoaderBase() {
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
			SWFDecoderWrapper.load(new data(), function(decodedDO:DisplayObject):void{
				addDecodedFile(name, decodedDO);
				standaloneFilesInProcess -= 1;
			}, function():void{
				CONFIG::debug
				{
					trace('[STANDALONE DECODING ERROR]');
				}
			});

			standaloneFilesInProcess += 1;
		}

		/**
		 * Добавить разэнкоженный файл
		 */
		private function addDecodedFile(name:String, content:DisplayObject):void
		{
			swfADs[name] = content.loaderInfo.applicationDomain || ApplicationDomain.currentDomain;
			swfs[name].loaded = true;
		}
	}
}
