package com.somewater.rabbit.application.commands
{
import com.somewater.rabbit.application.MainMenuPage;
import com.somewater.rabbit.application.windows.NeedMoreEnergyWindow;
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
				Config.application.startGame(level);
			}else{
				new NeedMoreEnergyWindow(function():void{
					Config.application.startGame(level);
				}, function():void {
					Config.application.startPage("main_menu");
				})
			}
		}
	}
}