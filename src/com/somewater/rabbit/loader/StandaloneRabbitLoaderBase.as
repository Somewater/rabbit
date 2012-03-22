package com.somewater.rabbit.loader {
	import com.somewater.net.SWFDecoderWrapper;
	import com.somewater.net.ServerHandler;
	import com.somewater.rabbit.storage.Config;
	import com.somewater.social.SocialUser;

	import flash.display.DisplayObject;
	import flash.events.Event;
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

		/**
		 * Помещаем сюда файлы на обработку в формате
		 * {name:'RabbitGame', data:Class}
		 */
		protected var standaloneFilesQueue:Array = [];

		private var startDecodingCallback:Function;

		public function StandaloneRabbitLoaderBase() {
			super();

			if(swfs == null)
				swfs = {};
		}


		override protected function createSpecificPaths():void {
			// nothing
		}

		protected function startDecoding(onComplete:Function):void
		{
			if(startDecodingCallback != null)
				throw new Error('Only one thread');
			startDecodingCallback = onComplete;
			addEventListener(Event.ENTER_FRAME, onDecodeEnterFrame);
		}

		private function onDecodeEnterFrame(event:Event):void {
			if(standaloneFilesInProcess == 0)
			{
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
				standaloneFilesInProcess -= 1;
			}, function():void{
				CONFIG::debug
				{
					trace('[STANDALONE DECODING ERROR]');
				}
			});
		}

		/**
		 * Добавить разэнкоженный файл
		 */
		private function addDecodedFile(name:String, content:DisplayObject):void
		{
			swfADs[name] = content.loaderInfo.applicationDomain || ApplicationDomain.currentDomain;
			if(swfs[name] == null)
				swfs[name] = {};
			swfs[name].loaded = true;
		}

		override protected function initializeServerHandler():void
		{
			_serverHandler = new ServerHandler();
			_serverHandler.base_path = /(asflash|atlantor)/.test(loaderInfo.url) ? String(loaderInfo.url).substr(0, String(loaderInfo.url).indexOf('/', 10) + 1) : "http://localhost:3000/";
			_serverHandler.init(getUser().id, 'embed', net);
		}

		//////////////////////////////////////////////////////////////////
		//																//
		//		S O C I A L     A P I    I M P L E M E N T A T I O N 	//
		//																//
		//////////////////////////////////////////////////////////////////

		override public function get net():int { throw new Error('Must be overriden') }

		override public function getUser():SocialUser
		{
			if(user == null)
				loadUserData();
			return user;
		}

		override public function setUser(user:SocialUser):void {
			saveUserData(user);
		}

		private var user:SocialUser;

		private function loadUserData():void
		{
			var userParams:Object = this.get('user');
			if(userParams == null)
				userParams = {};
			user = new SocialUser();
			user.male = true;
			user.id = userParams['id'] ? userParams['id'] : '0';
			user.itsMe = true;
			user.balance = 0;
			user.bdate = new Date(1980, 0, 0).time;
			user.firstName = userParams['firstName'] ? userParams['firstName'] : "Rabbit";
			user.lastName = userParams['lastName'] ? userParams['lastName'] : "";
		}

		private function saveUserData(user:SocialUser):void {
			var userParams:Object = {"id": user.id};
			this.set('user', userParams);
		}
	}
}
