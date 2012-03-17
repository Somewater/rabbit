package com.somewater.rabbit.events {
	import com.somewater.rabbit.storage.LevelDef;

	import flash.events.Event;

	public class GameModuleEvent extends Event{

		/**
		 * игровой модуль проинициализирован и стартовал
		 */
		public static const GAME_MODULE_STARTED_EVENT:String = 'gameModuleStartedEvent';

		/**
		 * Собран ревард на посещение друга
		 */
		public static const FRIEND_VISIT_REWARD_HARVESTED:String = 'friendVisitRewardHarvested';

		public var level:LevelDef

		public function GameModuleEvent(type:String, level:LevelDef) {
			this.level = level;
			super(type);
		}
	}
}
