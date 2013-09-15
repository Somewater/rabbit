package com.somewater.rabbit
{
	import com.somewater.rabbit.managers.IGameTutorialModule;
	import com.somewater.rabbit.storage.LevelDef;
	import com.somewater.rabbit.storage.LevelInstanceDef;
	
	import flash.events.IEventDispatcher;
	import flash.geom.Point;

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
		function finishLevel(event:LevelInstanceDef):void

		/**
		 * Воскрестить мертвого кролика, вырастить съеденные воронами морковки или добавить времени
		 */
		function continueLevel(event:LevelInstanceDef):void
		
		/**
		 * Уровень, который включен в игре в данный момент
		 */
		function get level():LevelDef
			
		function start():void
		
		function pause():void
			
		function get isTicking():Boolean
			
		function logError(reporter:*, method:String, message:String):void

		function initializeEditorModule():void

		function setTemplateTool(toolname:String, template:XML = null, objectReference:XML = null):IEventDispatcher

		function get tutorialModule():IGameTutorialModule

		function createOffer(x:int,  y:int):void

		function usePowerup(templateName:String):void

		function createFriendVisitReward():void

		function startPrepareBlitting():void

		function stopPrepareBlitting():void

		function entityToTile(entity:*):Point;
	}
}