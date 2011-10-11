package com.somewater.rabbit.application
{
	import com.somewater.controller.PopUpManager;
	import com.somewater.rabbit.storage.Config;
	import com.somewater.rabbit.storage.LevelDef;
	import com.somewater.rabbit.storage.Lib;
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
		private var friendBar:FriendBar;
		
		public function MainMenuPage()
		{
			var beginner:Boolean = false;// если не пройдено не олдного уровня
			buttons = [beginner?"START_GAME":"CONTINUE_GAME",
						"LEVEL_SELECTION",
						"MY_ACHIEVEMENTS",
						"ABOUT_GAME"
					  ];
			
			for(var i:int = 0;i<buttons.length;i++)
			{
				var b:OrangeButton = new OrangeButton();
				b.label = Lang.t(buttons[i]);
				buttons[i] = b;
				b.addEventListener(MouseEvent.CLICK, onSomeButtonClick);
				b.setSize(180, 32);
				b.x = (Config.WIDTH - b.width) * 0.5;
				b.y = 130 + 55 * i;
				addChild(b);
			}
			
			if(Config.loader.hasFriendsApi)
			{
				friendBar = new FriendBar();
				friendBar.x = 35;
				friendBar.y = Config.HEIGHT -  FriendBar.HEIGHT - 40;
				addChild(friendBar);
			}
		}
		
		override public function clear():void
		{
			for(var i:int = 0;i<buttons.length;i++)
				buttons[i].removeEventListener(MouseEvent.CLICK, onSomeButtonClick);
			if(friendBar)
				friendBar.clear();
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
			switch(OrangeButton(e.currentTarget).label)
			{
				case 	Lang.t("START_GAME"):
				case 	Lang.t("CONTINUE_GAME"):
						var levelNumber:int = UserProfile.instance.levelNumber;
						var nextLevel:LevelDef = Config.application.getLevelByNumber(levelNumber + 1);
					 	Config.application.startGame(nextLevel ? nextLevel : Config.application.getLevelByNumber(levelNumber));
						break;
				case Lang.t("LEVEL_SELECTION"):
						Config.application.startPage("levels");
						break;
				case Lang.t("MY_ACHIEVEMENTS"):
						PopUpManager.message("TODO: раздел в разработке");
						break;
				case Lang.t("ABOUT_GAME"):
						Config.application.startPage("about");
						break;
			}
		}
	}
}