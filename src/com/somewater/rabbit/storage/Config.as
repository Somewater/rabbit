package com.somewater.rabbit.storage
{
	import com.somewater.rabbit.IRabbitApplication;
	import com.somewater.rabbit.IRabbitEditor;
	import com.somewater.rabbit.IRabbitGame;
	import com.somewater.rabbit.IRabbitLoader;

	import flash.display.Stage;
	import flash.events.Event;
	import flash.events.IEventDispatcher;


	/**
	 * Хранилище статичных конфигов игры
	 */
	public class Config
	{
		public static var loader:IRabbitLoader;
		
		public static var application:IRabbitApplication;
		
		public static var game:IRabbitGame;

		CONFIG::debug
		{
			public static var editor:IRabbitEditor;
		}

		/**
		 * Для нетипизированных данных
		 * hideTop
		 * showTopButton показать кнопку, по которой открывается топ
		 * customTop function(user:UserProfile):void показ топа вне флешки
		 * hideShop
		 * autoPostLevelPass - автоматически стартовать постинг пройденного уровня
		 * portfolioMode - включен режим портфолио, максимально раскрывающий воз-ти игры
		 * 'lang_pack' - нераспарсенный словарь ключей
		 * drawTileGrid - рисовать сетку тайлов
		 * disableCameraTracking - отключить автоматическое слежение камеры за персонажем
		 */
		public static var memory:Object = {};
		
		/**
		 * Означает, что игровой модуль запущен
		 * (если игра на паузе, все равно true)
		 */
		public static var gameModuleActive:Boolean = false;
		public static var editorActive:Boolean = false;
		public static var editorOver:Boolean = false;

		/**
		 * Производить блиттинг
		 */
		public static var blitting:Boolean = true;
		
		public static var stage:Stage;
		
		public static var WIDTH:int = 810;
		
		public static var HEIGHT:int = 650;
		
		public static const TILE_WIDTH:int = 90;
		
		public static const TILE_HEIGHT:int = 50;
		
		public static const FRAME_RATE:int = 30;
		
		// ширина/высота в тайлах
		public static var T_WIDTH:int;
		public static var T_HEIGHT:int;
		
		/**
		 * Высота задней подложки в тайлах
		 * (соответственно, сколько тайлов, как исключение, будет видно сверху за границей игрового поля)
		 */
		public static var HORIZONT_HEIGHT:int = 4;
		
		/**
		 * Пересчитать параметры класса (запускается модулем RabbitGame !!!)
		 */
		public static function init():void
		{
			T_WIDTH = WIDTH / TILE_WIDTH;
			
			T_HEIGHT = HEIGHT / TILE_HEIGHT;
		}
		
		public static const FONT_PRIMARY:String = "a_FuturaRound";
		public static const FONT_SECONDARY:String = "Arial";

		public static function callLater(callback:Function, args:Array = null, pendingFrames:int = 0):void
		{
			stage.addEventListener(Event.ENTER_FRAME, function(event:Event):void{
				if(pendingFrames <= 0)
				{
					IEventDispatcher(event.currentTarget).removeEventListener(event.type, arguments.callee);
					callback.apply(null, args);
				}
				else
					pendingFrames--;
			})
		}

		public static var pendingStats:Array = [];
		public static function stat(name:String):void
		{
			if(application)
				application.stat(name);
			else
				pendingStats.push(name);
		}

		public static function get isAdmin():Boolean
		{
			return loader && loader.getUser() && loader.getUser().id == '245894';
		}
	}
}
