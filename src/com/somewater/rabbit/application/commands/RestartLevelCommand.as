package com.somewater.rabbit.application.commands
{
	import com.somewater.rabbit.storage.Config;
	import com.somewater.rabbit.storage.LevelDef;
	import com.somewater.rabbit.storage.LevelInstanceDef;
	import com.somewater.rabbit.storage.UserProfile;

	public class RestartLevelCommand implements ICommand
	{
		public function RestartLevelCommand()
		{
		}
		
		public function execute():void
		{
			var level:LevelDef = Config.game.level;
			Config.game.finishLevel(LevelInstanceDef.DUMMY_FATAL_LEVEL);

			if(UserProfile.instance.canSpendEnergy()){
				UserProfile.instance.spendEnergy();
				Config.application.startGame(level);
			}else{
				Config.application.message("NEED_MORE_ENERGY_ERROR");
			}
		}
	}
}