package com.somewater.rabbit.loader
{
	
	import com.somewater.net.IServerHandler;
	import com.somewater.net.UrlQueueLoader;
	import com.somewater.rabbit.IRabbitApplication;
	import com.somewater.rabbit.IRabbitGame;
	import com.somewater.rabbit.IRabbitLoader;
	import com.somewater.rabbit.storage.Config;
	import com.somewater.social.SocialUser;
	
	import flash.display.DisplayObject;
	import flash.display.Loader;
	import flash.display.LoaderInfo;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.ProgressEvent;
	import flash.net.URLRequest;
	import flash.system.ApplicationDomain;
	import flash.system.LoaderContext;
	import flash.system.Security;
	import flash.system.SecurityDomain;

	public class RabbitLoaderBase extends Sprite implements IRabbitLoader
	{
		
		protected var swfLoader:Loader;
		protected var preloader:*;
		private var preloaderCarrotIndex:int = -1;// индекс последней запущенной морковки
		protected var normalStartFlag:Object;
		
		protected var gameLoadingMode:int = 0;
		
		/**
		 * Сылка на объект с флашварсами (должна инициализироваться расширяющим классом)
		 */
		protected var _flashVars:Object;
		
		/**
		 * Ключ обращения к api (должен задаваться расширяющим классом)
		 */
		protected var key:String;
		
		/**
		 * Сигнализирует о том, что флешка запущена локально
		 */
		protected var DESKTOP_MODE:Boolean = false;
		
		/**
		 * Режим тестирования. Если false автоматически отключаются любые другие флаги тестирования
		 */
		public var TEST_MODE:Boolean = CONFIG::debug;
		
		/**
		 * Прописаны пути до всех swf-ok
		 * swfs["Game"] = {	"priority":0, 
		 * 					"preload":true, 
		 * 					"url":"http://...", 
		 * 					"loaded": null
		 * 				  }
		 */
		public var swfs:Object;
		
		/**
		 * Содержит ApplicationDomain всех загруженных swf
		 * swfADs["Game"]:ApplicationDomain
		 */
		protected var _swfADs:Array = [];
		
		/**
		 * Массив объектов XML, индекстированных по именам файлов (без xml)
		 */
		private var _filesData:Array = [];
		public function getXML(name:String):XML{ if(!(_filesData[name] is XML))_filesData[name] = new XML(_filesData[name]);return _filesData[name] as XML;}	
		public function setXML(name:String, data:XML):void{_filesData[name] = data;}
		public function getData(name:String):String{ return _filesData[name]; }	
		public function setData(name:String, data:String):void{_filesData[name] = data;}
		
		/**
		 * Хранить соответствия имени(идентификатора) файла и пути, по которому его можно загрузить
		 * _filePaths["Description.xml"] == "http://somesite.ru/release/Description.v23.xml"
		 */
		protected var filePaths:Object;
		
		
		// аргументы вызова функции loadSwfs
		private var _loadSwfsQueue:Array;
		private var _loadSwfsOnComplete:Function;
		private var _loadSwfsOnError:Function;
		private var _loadSwfsOnProgress:Function;
		
		// слои интерфейса игры
		protected var _content:Sprite;
		protected var _popups:Sprite;
		protected var _tooltips:Sprite;
		protected var _cursors:Sprite;

		protected var _serverHandler:IServerHandler;
		private var _basePath:String = null;
		
		/**
		 * Какой элемент массива _loadSwfsQueue загружается в данный момент
		 */
		private var _loadSwfsQueueIterator:int;
		
		[Embed(source="./../../../../assets/swc/preloader.swf", symbol="preloader.Preloader")]
		private var PRELOADER_CLASS:Class;
		
		CONFIG::debug
		{
			//[Embed(source="./../bin-debug/Rabbit.swf", mimeType='application/octet-stream')]
			private var GAME_CLASS:Class;
		}
		
		public function RabbitLoaderBase()
		{		
			createLayers();
			
			preloader = new PRELOADER_CLASS();
			for(var i:int = 0; i < 10; i++)
				preloader.bar["carrot" + i].stop();
			
			addChild(preloader);
			setProgress(0, 0);
			
			tabChildren = false;
			
			Security.allowDomain("*");
			
			addEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
		}
		
		public function get flashVars():Object{	return _flashVars	}
		
		public function get content():Sprite{	return _content	}
		
		public function get popups():Sprite{	return _popups	}
		
		public function get tooltips():Sprite{	return _tooltips	}
		
		public function get cursors():Sprite{	return _cursors	}
		
		public function get swfADs():Array{ return _swfADs;}
		
		public function getFilePath(fileId:String):String{ return filePaths[fileId]; }
		
		protected function createLayers():void
		{
			_content = new Sprite();
			addChild(_content);
			
			_popups = new Sprite();
			addChild(_popups);
			
			_tooltips = new Sprite();
			addChild(_tooltips);
			
			_cursors = new Sprite();
			addChild(_cursors);
		}
		
		private function onAddedToStage(e:Event):void{
			
			graphics.beginFill(0xE7E7E7);
			graphics.drawRect(0, 0, stage.stageWidth, stage.stageHeight);
			
			removeEventListener(e.type, onAddedToStage);
			
			stage.align = StageAlign.TOP_LEFT;
			stage.scaleMode = StageScaleMode.NO_SCALE;
			stage.showDefaultContextMenu = false;
			
			CONFIG::debug
			{
				stage.showDefaultContextMenu = true;
			}
			
			Config.loader = this;
			Config.WIDTH = stage.stageWidth;
			Config.HEIGHT = stage.stageHeight;
			
			preloader.x = (stage.stageWidth - preloader.width) * 0.5;
			preloader.y = (stage.stageHeight - preloader.height) * 0.5 - 20;
			if(stage.stageHeight < 500)
			{
				preloader.logo.y += 15;
				preloader.bar.y -= 15;
			}
			
			_flashVars = this;
			CONFIG::debug
			{
				DESKTOP_MODE = (loaderInfo.url == null || loaderInfo.url.indexOf("file:///") == 0) && TEST_MODE;
			}
			
			netInitialize();
		}
		
		/**
		 * Получить все необходимые данные от соц. сети либо аггрегатора игр и вызвать метод
		 * onNetInitializeComplete
		 */
		protected function netInitialize():void{							
			throw new Error("Must get site, social on net info");
		}
		
		protected function onNetInitializeComplete():void{
			setProgress(0, 1);
			
			createSpecificPaths();
			initializeServerHandler();
			
			if(swfs == null || filePaths == null)
				throw new Error("Lazy localization!");
			
			startSwfLoading();
		}

		protected function initializeServerHandler():void
		{
			throw new Error("Must be overriden")
		}

		public function get serverHandler():IServerHandler
		{
			return _serverHandler
		}
		
		protected function createSpecificPaths():void
		{
			throw new Error("Create specific paths in `swfs` and `filePaths`");
		}
		
		
		protected function startSwfLoading():void
		{
			var initLoadingQueue:Array = createInitLoadingSwfs();
			loadSwfs(initLoadingQueue, initSwfOnComplete, initSwfOnError, initSwfOnProgress);
		}
		
		
		/**
		 * Создать, если необходимо, массив swfs
		 * Возвратить массив флешек, которые должны быть загружены в первую очередь, на основе массива swfs
		 */
		protected function createInitLoadingSwfs():Array
		{
			if(swfs == null)
				throw new Error("Undefined preloading swfs queue");
			
			var swfsPreloading:Array = [];
			for(var swfname:Object in swfs)
			{
				var swf:Object = swfs[swfname];
				swf.name = swfname;
				if(swf.preload)
					swfsPreloading.push(swf);
			}
			
			swfsPreloading.sortOn("priority", Array.DESCENDING | Array.NUMERIC);
			
			return swfsPreloading;
		}
		
		
		protected function onNetInitializeError():void{
			trace("onSocialError");
		}
		
		/**
		 * Очистка для GC
		 */
		public function clear():void
		{
			if(preloader)
			{
				if(preloader.parent)
					preloader.parent.removeChild(preloader)
				preloader = null;
			}
			
		}
		
		/**
		 * ВОзвращает прелоадер для дальнейшего использования
		 */
		public function allocatePreloader():*
		{
			var p:* = preloader;
			clear();
			return p;
		}
		
		
		//////////////////////////////////////////
		//
		//
		//		START IRabbitLoader implementation		
		//
		//
		//////////////////////////////////////////
		
		
		/**
		 * Загрузить очередь
		 */
		public function loadSwfs(queue:Array, 
										  onComplete:Function, 
										  onError:Function = null, 
										  onProgress:Function = null):void
		{
			_loadSwfsQueue = queue || [];
			_loadSwfsOnComplete = onComplete;
			_loadSwfsOnError = onError;
			_loadSwfsOnProgress = onProgress;
			
			_loadSwfsQueueIterator = 0;
			
			loadNextSwf(null);
		}
		
		
		/**
		 * Приступить к загрузке флешек из swfs
		 */
		protected function loadNextSwf(event:Object):void
		{
			var swfToLoading:Object = _loadSwfsQueue[_loadSwfsQueueIterator];			
			var url:String = swfToLoading.url;
			var name:String = swfToLoading.name;
			
			if(event)
			{
				if(event is Event)
				{
					if(swfs[name])
					{
						swfs[name].loaded = true;
					}
					LoaderInfo(_swfADs[name]).removeEventListener(IOErrorEvent.IO_ERROR, swfLoadingError);
					LoaderInfo(_swfADs[name]).removeEventListener(ProgressEvent.PROGRESS, swfLoadingProgress);
					LoaderInfo(_swfADs[name]).removeEventListener(Event.COMPLETE, loadNextSwf);
					_swfADs[name] = LoaderInfo(event.currentTarget).applicationDomain;
					processLoadedSwf(event.currentTarget.content, name);
					swfLoader = null;
				}
				
				_loadSwfsQueueIterator++;
				
			}
			
			_loadSwfsOnProgress && _loadSwfsOnProgress((_loadSwfsQueueIterator)/_loadSwfsQueue.length);
			
			swfToLoading = _loadSwfsQueue[_loadSwfsQueueIterator];
			
			if(swfToLoading == null)
			{
				// очередь пуста
				_loadSwfsOnComplete && _loadSwfsOnComplete();
				return
			}
			
			if(swfToLoading.url == null && swfToLoading.name && swfs[swfToLoading.name])
			{
				// присваеваем  url на основе name
				swfToLoading.url = swfs[swfToLoading.name].url;
			}
			
			url = swfToLoading.url;
			if(url.substr(0,4) != "http" && _basePath && _basePath.length)
				url = (_basePath.substr(_basePath.length - 1,1) == "/" ? _basePath : _basePath + "/") + url;
			name = swfToLoading.name;
			
			//проверить, не была ли swf загружена ранее
			if(swfs[swfToLoading.name] && swfs[swfToLoading.name].loaded)
			{
				loadNextSwf(true);
				return;
			}
			for each(var swf:Object in swfs)
				if(swf.loaded && swf.url == url)
				{
					loadNextSwf(true);
					return;
				}

			var request:URLRequest = new URLRequest(url);
			var context:LoaderContext = new LoaderContext(false, ApplicationDomain.currentDomain, (DESKTOP_MODE?null:SecurityDomain.currentDomain)); 
			
			swfLoader = new Loader();
			_swfADs[name] = swfLoader.contentLoaderInfo;
			swfLoader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, swfLoadingError);
			swfLoader.contentLoaderInfo.addEventListener(ProgressEvent.PROGRESS, swfLoadingProgress);
			swfLoader.contentLoaderInfo.addEventListener(Event.COMPLETE, loadNextSwf);
			
			swfLoader.load(request, context);
		}
		
		
		protected function processLoadedSwf(swf:DisplayObject, name:String):void
		{
			CONFIG::debug
			{
				if(name == "Editor")
				{
					swf.x = Config.WIDTH;
					stage.addChild(swf);
				}
			}
		}
		
		/**
		 * Приложение не может быть загружено
		 */
		private function swfLoadingError(e:IOErrorEvent):void{
			_loadSwfsOnError && _loadSwfsOnError();
		}
		
		/**
		 * Приоложение загружается
		 */
		private function swfLoadingProgress(e:ProgressEvent):void{
			var value:Number = e.bytesLoaded/e.bytesTotal;
			if(_loadSwfsOnProgress != null)
			{
				_loadSwfsOnProgress((_loadSwfsQueueIterator + value) / _loadSwfsQueue.length);
			}
		}
		
		public function load(data:Object, onComplete:Function = null, onError:Function = null, onProgress:Function = null):void
		{
			// пытаемся найти файлы, которые уже были загружены ранее
			var alreadyLoaded:Array = [];
			var hasMissingFiles:Boolean = false;// в массиве на загрузку всёже есть файлы, которые еще не были загружены
			for(var filename:String in data)
				if(_filesData[filename])
				{
					alreadyLoaded[filename] = _filesData[filename]
					delete(data[filename]);
				}
				else
					hasMissingFiles = true;
			
			if(hasMissingFiles)
				// делегируем задачу на класс UrlQueueLoader
				UrlQueueLoader.load(data, innerOnComplete, onError, onProgress);
			else
				innerOnComplete([]);
			
			function innerOnComplete(loadedFiles:Object):void
			{
				for(var filename:String in loadedFiles)
				{
					setData(filename, loadedFiles[filename]);
					alreadyLoaded[filename] = loadedFiles[filename];
				}
				onComplete(alreadyLoaded);
			}
		}
		
		
		//////////////////////////////////////////
		//
		//
		//		END IRabbitLoader implementation		
		//
		//
		//////////////////////////////////////////
		
		protected function initSwfOnError():void
		{
			trace("[INIT SWF] ERROR LOADING: " + _loadSwfsQueue[_loadSwfsQueueIterator].name + " on url \"" + _loadSwfsQueue[_loadSwfsQueueIterator].url + "\"");
		}
		
		protected function initSwfOnProgress(value:Number):void
		{
			setProgress(1, value);
			trace("[INIT SWF] PROGRESS: " + value.toFixed(2));
		}
		
		protected function initSwfOnComplete():void
		{
			setProgress(1, 1);
			trace("[INIT SWF] COMPLETE");
			
			var application:IRabbitApplication = Config.application;
			
			if(application == null)
			{
				var applicationClass:Class = ApplicationDomain(_swfADs["Application"]).getDefinition("RabbitApplication") as Class;
				application = new applicationClass();
				Config.application = application;
			}
			
			var game:IRabbitGame = Config.game;
			
			if(game == null)
			{
				var gameClass:Class = ApplicationDomain(_swfADs["Game"]).getDefinition("RabbitGame") as Class;
				game = new gameClass();
				Config.game = game;
			}
			
			onApplicationLoaded(application, game);
		}
		
		
		public function setProgress(type:int, value:Number):void
		{
			if(preloader)
			{	
				value = ([0, 0.1, 0.6, 0.9] as Array)[type] + ([0.1, 0.5, 0.3, 0.1] as Array)[type] * value;
				preloader.bar.textField.text = Math.round(value * 100) + "%";
				preloader.bar.progressBar.scaleX = 1 - value;
				for(var nextCarrotIndex:int = Math.min(9,Math.round(value * 10));preloaderCarrotIndex < nextCarrotIndex;preloaderCarrotIndex++)
				{
					var carrot:MovieClip = preloader.bar["carrot" + (preloaderCarrotIndex + 1)];
					carrot.play();
					carrot.addFrameScript(carrot.totalFrames-1, function(...args):void{
						carrot.stop();
					});
				}
			}
		}
		
		/**
		 * Приложене было загружено
		 */
		private function onApplicationLoaded(app:IRabbitApplication, game:IRabbitGame):void{
			runApplication(app);
		}
		
		/**
		 * Передать приложению какие-то специфические данные 
		 * (если требуются в конкретной реализации)
		 * и запустить
		 */
		protected function runApplication(app:IRabbitApplication):void{
			app.run();
		}
		
		
		
		
		
		//////////////////////////////////////////////
		//											//
		//			S O C I A L     A P I			//
		//											//
		//////////////////////////////////////////////
		
		public function get hasUserApi():Boolean
		{
			return false;	
		}
		
		public function get hasFriendsApi():Boolean
		{
			return false;	
		}
		
		public function getFriends():Array
		{
			throw new Error("Must be overriden");
		}
			
		public function getAppFriends():Array
		{
			throw new Error("Must be overriden");
		}
			
		public function getUser():SocialUser
		{
			throw new Error("Must be overriden");
		}
			
		public function showInviteWindow():void
		{
			throw new Error("Must be overriden");
		}
			
		public function pay(quantity:Object, onSuccess:Function, onFailure:Function):void
		{
			throw new Error("Must be overriden");
		}
		
		public function getUsers(uids:Array, onComplete:Function, onError:Function):void
		{
			throw new Error("Must be overriden");
		}
		
		public function set basePath(value:String):void
		{
			_basePath = value;
		}
	}
}
