package com.somewater.rabbit
{
	import com.somewater.rabbit.storage.LevelDef;

	import flash.events.IEventDispatcher;

	/**
	 * Его реализует игровой модуль игры, предоставляя api
	 * для его управления
	 */
	public interface IRabbitGame extends IRabbitModule
	{
		/**
		 * Инициализирует менеджеры игры и подготавливается к запуску уровня
		 * @param callback вызывается, косле того, как игровой модуль выполнил свою инициализацию
		 */
		function run(callback:Function = null):void
			
		/**
		 * Стартовать указанный уровень
		 * @param level
		 * @param callback вызывается, когда игра стартовала
		 */
		function startLevel(level:LevelDef, callback:Function = null):void
		
		/**
		 * Закончить игру и переключиться на страницу уровней в приложении
		 */
		function finishLevel(success:Boolean):void
		
		/**
		 * Уровень, который включен в игре в данный момент
		 */
		function get level():LevelDef
			
		function start():void
		
		function pause():void
			
		function get isTicking():Boolean
			
		function logError(reporter:*, method:String, message:String):void

		function setTemplateTool(template:XML):IEventDispatcher
	}
}