package com.somewater.rabbit.application.commands
{
	import com.somewater.rabbit.storage.Config;
	import com.somewater.rabbit.storage.LevelDef;
	import com.somewater.rabbit.storage.LevelInstanceDef;

	public class RestartLevelCommand implements ICommand
	{
		public function RestartLevelCommand()
		{
		}
		
		public function execute():void
		{
			var level:LevelDef = Config.game.level;
			Config.game.finishLevel(LevelInstanceDef.DUMMY_FATAL_LEVEL);
			Config.application.startGame(level);
		}
	}
}