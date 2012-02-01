package com.somewater.rabbit.application
{
	import com.somewater.controller.PopUpManager;
	import com.somewater.rabbit.application.commands.OpenRewardLevelCommand;
	import com.somewater.rabbit.application.commands.StartNextLevelCommand;
	import com.somewater.rabbit.storage.Config;
	import com.somewater.rabbit.storage.LevelDef;
	import com.somewater.rabbit.storage.Lib;
	import com.somewater.rabbit.storage.RewardLevelDef;
	import com.somewater.rabbit.storage.UserProfile;
	import com.somewater.storage.Lang;
	
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.Sprite;
	import flash.events.MouseEvent;
	import flash.text.TextField;

	public class MainMenuPage extends PageBase
	{
		private var buttons:Array;
		private var audioControls:AudioControls
		private var friendBar:FriendBar;
		
		public function MainMenuPage()
		{
			var beginner:Boolean = UserProfile.instance.levelNumber == 1;// если не пройдено не олдного уровня
			buttons = [beginner?"START_GAME":"CONTINUE_GAME",
						"LEVEL_SELECTION",
						"MY_ACHIEVEMENTS",
						"ABOUT_GAME"
					  ];

			var b:OrangeButton;
			for(var i:int = 0;i<buttons.length;i++)
			{
				b = new OrangeButton();
				b.label = Lang.t(buttons[i]);
				buttons[i] = b;
				b.addEventListener(MouseEvent.CLICK, onSomeButtonClick);
				b.setSize(180, 32);
				b.x = (Config.WIDTH - b.width) * 0.5;
				b.y = 115 + 55 * i;
				addChild(b);
			}
			audioControls = new AudioControls();
			audioControls.x = b.x;
			audioControls.y = b.y + 55;
			addChild(audioControls);
			
			if(Config.loader.hasFriendsApi)
			{
				friendBar = new FriendBar();
				friendBar.x = 35;
				friendBar.y = Config.HEIGHT -  FriendBar.HEIGHT - 40;
				addChild(friendBar);
			}

			logo.visible = (friendBar == null || friendBar.x + FriendBar.WIDTH + 10 < logo.x) && logo.x + logo.width < Config.WIDTH;
		}
		
		override public function clear():void
		{
			for(var i:int = 0;i<buttons.length;i++)
				buttons[i].removeEventListener(MouseEvent.CLICK, onSomeButtonClick);
			if(friendBar)
				friendBar.clear();
			audioControls.clear();
		}
		
		override protected function createGround():void
		{
			super.createGround();
			var subGround:DisplayObject = Lib.createMC("interface.MainPageGround");
			subGround.x = (Config.WIDTH - 810) * 0.5;
			subGround.y = (Config.HEIGHT - 655) * 0.5;
			addChild(subGround);
		}
		
		private function onSomeButtonClick(e:MouseEvent):void
		{
			if(!OrangeButton(e.currentTarget).enabled)
				return;

			switch(OrangeButton(e.currentTarget).label)
			{
				case 	Lang.t("START_GAME"):
				case 	Lang.t("CONTINUE_GAME"):
					 	new StartNextLevelCommand().execute();
						break;
				case Lang.t("LEVEL_SELECTION"):
						Config.application.startPage("levels");
						break;
				case Lang.t("MY_ACHIEVEMENTS"):
						new OpenRewardLevelCommand(UserProfile.instance).execute();
						break;
				case Lang.t("ABOUT_GAME"):
						Config.application.startPage("about");
						break;
			}
		}

		// для тьюториала
		public function get startGameButton():OrangeButton
		{
			return buttons[0];
		}

		// для тьюториала
		public function disableButtons(disable:Boolean = true):void
		{
			for each(var b:OrangeButton in buttons)
				b.enabled = !disable;
		}
	}
}