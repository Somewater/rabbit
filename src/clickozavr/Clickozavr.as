package clickozavr
{
	import flash.display.DisplayObject;
	import flash.display.Loader;
	import flash.display.LoaderInfo;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IEventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.events.SecurityErrorEvent;
	import flash.geom.Rectangle;
	import flash.net.URLRequest;
	import flash.system.ApplicationDomain;
	import flash.system.LoaderContext;
	import flash.utils.describeType;
	
	[Event(name="getUserData", type="clickozavr.ClickozavrEvent")]
	[Event(name="containersReady", type="clickozavr.ClickozavrEvent")]
	
	/**
	 * @author jvirkovskiy
	 * Класс, добавляющий контейнеры Clickozavr в приложение
	 */
	
	public class Clickozavr extends EventDispatcher
	{
		
		////////////////////////////////////////////////////
		// 
		////////////////////////////////////////////////////
		
		private var _containers:Array;
		private var _loadCtr:int = 0;
		
		private var _waitForUserData:Boolean;
		private var _pKey:String;
		private var _pid:String;
		
		protected var _containerHolder:Sprite;				// Контейнер для контейнеров баннеров
		protected var _richMediaHolder:Sprite;				// Контейнер для контейнера richMedia
		
		protected var _appWidth:Number;						// Ширина приложения
		protected var _appHeight:Number;					// Высота приложения
		
		////////////////////////////////////////////////////
		// 
		////////////////////////////////////////////////////
		
		/**
		 * Конструктор
		 * @param appWidth ширина приложения
		 * @param appHeight высота приложения
		 * @param containerHolder слой, на котором размещены контейнеры
		 * @param richMediaHolder слой, на котором размещен баннер richMedia
		 * @param pKey приватный ключ приложения Mail.ru
		 */
		public function Clickozavr(pid:String, appWidth:Number, appHeight:Number,
								   containerHolder:Sprite, richMediaHolder:Sprite = null,
								   pKey:String = null)
		{
			super(null);
			
			_pid = pid;
			_appWidth = appWidth;
			_appHeight = appHeight;
			_containerHolder = containerHolder;
			_richMediaHolder = richMediaHolder;
			_pKey = pKey;
		}
		
		/**
		 * Инициализация и загрузка контейнеров
		 */
		public function init(containerList:Array, waitForUserData:Boolean = false):void
		{
			_waitForUserData = waitForUserData;
			
			// Список контейнеров, размещенных в приложении
			_containers = [];
			for each (var ci:ContainerInfo in containerList)
				_containers.push({ url: ci.url, x: ci.x, y: ci.y, type: ci.type });
			
			for each (var data:Object in _containers)
			{
				var loader:Loader = new Loader();
				
				loader.contentLoaderInfo.addEventListener(Event.INIT, container_initHandler);
				loader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, container_errorHandler);
				loader.contentLoaderInfo.addEventListener(SecurityErrorEvent.SECURITY_ERROR, container_errorHandler);
				
				loader.load(new URLRequest(data.url), new LoaderContext(false, ApplicationDomain.currentDomain));
				
				data.loader = loader;
				_loadCtr++;
			}
		}
		
		/**
		 * Загрузка контейнера успешно завершена
		 * @param event событие
		 */
		private function container_initHandler(event:Event):void
		{
			var loaderInfo:LoaderInfo = LoaderInfo(event.target);
			var data:Object = clearLoaderInfo(loaderInfo);
			
			var implemented:XMLList = describeType(event.target.content).implementsInterface;
			for each (var impl:XML in implemented)
			{
				if (impl.@type == "base::IClickozavrContainer")
				{
					// Загруженный клип является контейнером
					
					var item:Object = event.target.content;
					data.instance = item;
					
					item.waitForSupercontainer = _waitForUserData;		// Если этот флаг установлен в true, то приложение должно будет передать
																		// контейнеру информацию о пользователе (см. getUserInfo())
					
					if (item.hasOwnProperty("VERSION"))
						item.VERSION = "1.0.0.0";			// Здесь можно указать контейнеру версию приложения,
															// которая будет передана на сервер статистики
					if (item.hasOwnProperty("PKEY") && _pKey)
						item.PKEY = _pKey;
					
					if (item.hasOwnProperty("PID") && _pid)
						item.PID = _pid;
					
					// Разместить контейнер в приложении,
					// в зависимости от типа загруженного контейнера
					switch (data.type)
					{
						case ContainerInfo.WIDE:				// Контейнер 560x90
						case ContainerInfo.VERTICAL:			// Контейнер 150x500
						case ContainerInfo.USUAL:				// Контейнер 420x180
						case ContainerInfo.WIDE_EX:				// Контейнер 560x90w
						case ContainerInfo.VERTICAL_EX:			// Контейнер 150x500w
						case ContainerInfo.USUAL_EX:			// Контейнер 420x180w
						case ContainerInfo.BOTTOM_BAR:			// Контейнер 560x90wb
						{
							// Этим контейнерам достаточно задать местоположение в приложении
							DisplayObject(item).x = data.x;
							DisplayObject(item).y = data.y;
							
							_containerHolder.addChild(DisplayObject(item));
							break;
						}
					}
					break;
				}
			}
			
			if (_loadCtr <= 0)
				initMain();
		}
		
		/**
		 * Загрузка контейнера не удалась
		 * @param event событие
		 */
		private function container_errorHandler(event:Event):void
		{
			clearLoaderInfo(LoaderInfo(event.target));
			if (_loadCtr <= 0)
				initMain();
		}
		
		/**
		 * Вспомогательная функция очистки загрузчика
		 * @param loaderInfo загруженный loaderInfo
		 * @return данные контейнера
		 */
		private function clearLoaderInfo(loaderInfo:LoaderInfo):Object
		{
			loaderInfo.removeEventListener(Event.INIT, container_initHandler);
			loaderInfo.removeEventListener(IOErrorEvent.IO_ERROR, container_errorHandler);
			loaderInfo.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, container_errorHandler);
			
			_loadCtr--;
			
			for each (var data:Object in _containers)
			{
				if (data.loader == loaderInfo.loader)
				{
					delete data.loader;
					return data;
				}
			}
			return null;
		}
		
		/**
		 * Инициализация загруженных контейнеров
		 */
		protected function initMain():void
		{
			if (_waitForUserData)
				dispatchEvent(new ClickozavrEvent(ClickozavrEvent.GET_USER_DATA));
			else
				dispatchEvent(new ClickozavrEvent(ClickozavrEvent.CONTAINERS_READY));
		}
		
		/**
		 * Получить данные о пользователе из соцсети
		 * @param networkId id соцсети
		 * @param partnerId персональный id партнера Clickozavr
		 * @param appId id приложения
		 * @param data данные пользователя
		 */
		public function getUserData(networkId:String, partnerId:String, appId:String, userData:XML):void
		{
			for each (var data:Object in _containers)
			{
				if (data.hasOwnProperty("instance"))
					data.instance.sendUserData(networkId, partnerId, appId, userData);
			}
			
			dispatchEvent(new ClickozavrEvent(ClickozavrEvent.CONTAINERS_READY));
		}
	}
}