package com.somewater.rabbit.application
{
	import com.somewater.controller.PopUpManager;
	import com.somewater.rabbit.application.windows.LevelFinishSuccessWindow;
	import com.somewater.rabbit.application.windows.PendingRewardsWindow;
	import com.somewater.rabbit.storage.Config;
	import com.somewater.rabbit.storage.LevelDef;
	import com.somewater.rabbit.storage.LevelInstanceDef;
	import com.somewater.rabbit.storage.RewardDef;
	import com.somewater.rabbit.storage.RewardInstanceDef;
	import com.somewater.rabbit.xml.XmlController;

	import flash.utils.clearInterval;
	import flash.utils.setInterval;
	import flash.utils.setTimeout;

	public class AboutPage extends PageBase
	{
		public function AboutPage()
		{
			super();
			
			getButton("Это вот такая вот игра", this, 100,100);
			
			getButton("В главное меню", this, 100,200, function():void{
				Config.application.startPage("main_menu");
			});

			new PendingRewardsWindow([    RewardManager.instance.getByType(RewardDef.TYPE_REFERER)[0]    ]);
		}
	}
}