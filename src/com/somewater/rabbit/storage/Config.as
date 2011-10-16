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
		 */
		public static var memory:Object = {};
		
		/**
		 * Означает, что игровой модуль запущен
		 * (если игра на паузе, все равно true)
		 */
		public static var gameModuleActive:Boolean = false;
		
		public static var stage:Stage;
		
		public static var WIDTH:int = 810;
		
		public static var HEIGHT:int = 550;
		
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

		public static function callLater(callback, args:Array = null):void
		{
			stage.addEventListener(Event.ENTER_FRAME, function(event:Event):void{
				IEventDispatcher(event.currentTarget).removeEventListener(event.type, arguments.callee);
				callback.apply(null, args);
			})
		}
	}
}
