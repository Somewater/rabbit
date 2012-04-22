package com.somewater.rabbit.application
{
	import com.somewater.controller.PopUpManager;
	import com.somewater.rabbit.application.buttons.GreenButton;
	import com.somewater.rabbit.application.commands.OpenRewardLevelCommand;
	import com.somewater.rabbit.application.commands.StartNextLevelCommand;
	import com.somewater.rabbit.application.tutorial.TutorialLevelDef;
	import com.somewater.rabbit.application.tutorial.TutorialManager;
	import com.somewater.rabbit.storage.Config;
	import com.somewater.rabbit.storage.Config;
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
		private var offerStat:OfferStatPanel;
		
		public function MainMenuPage()
		{
			var beginner:Boolean = UserProfile.instance.levelNumber == 1;// если не пройдено не олдного уровня
			buttons = [beginner?"START_GAME":"CONTINUE_GAME",
						"LEVEL_SELECTION",
						"MY_ACHIEVEMENTS",
						"ABOUT_GAME"
					  ];

			buttons.splice((beginner ? 0 : 1), 0, 'TUTORIAL_BTN');

			if(!Config.memory['hideTop'] && UserProfile.instance.levelNumber > 1 && !TutorialManager.active)// т.е. человек прошел туториал
			{
				buttons.splice(buttons.indexOf('ABOUT_GAME'), 0, "USERS_TOP");// ставим пеерд "Об игре"
			}

			if(!Config.memory['hideShop'])
				buttons.splice(buttons.indexOf('MY_ACHIEVEMENTS'), 0, "SHOP_MENU_BTN");// ставим пеерд "Ми нарады"

			if(Config.loader.hasFriendsApi)
			{
				friendBar = new FriendBar();
				friendBar.x = 35;
				friendBar.y = Config.HEIGHT -  FriendBar.HEIGHT - 40;
				addChild(friendBar);
			}

			// +2 к количеству кнопок, т.к. учитываются контролы аудио (примерно как 2 кнопки по высоте)
			var buttonsY:int = ((friendBar ? friendBar.y : Config.HEIGHT) - ((buttons.length + 2) * 55)) * 0.5;

			var b:OrangeButton;
			for(var i:int = 0;i<buttons.length;i++)
			{
				b = buttons[i] == 'SHOP_MENU_BTN' ? new GreenButton() : new OrangeButton();
				b.label = Lang.t(buttons[i]);
				buttons[i] = b;
				b.addEventListener(MouseEvent.CLICK, onSomeButtonClick);
				b.setSize(180, 32);
				b.x = (Config.WIDTH - b.width) * 0.5;
				b.y = buttonsY + 55 * i;
				addChild(b);
			}
			audioControls = new AudioControls();
			audioControls.x = b.x;
			audioControls.y = b.y + 55;
			addChild(audioControls);
			
			if(logo.visible)
				logo.visible = (friendBar == null || friendBar.x + FriendBar.WIDTH + 10 < logo.x) && logo.x + logo.width < Config.WIDTH;

			offerStat = new OfferStatPanel(OfferStatPanel.INTERFACE_MODE);
			offerStat.x = Config.WIDTH - offerStat.width - 15;
			offerStat.y = 15;
			addChild(offerStat);
		}
		
		override public function clear():void
		{
			for(var i:int = 0;i<buttons.length;i++)
				buttons[i].removeEventListener(MouseEvent.CLICK, onSomeButtonClick);
			if(friendBar)
				friendBar.clear();
			audioControls.clear();
			offerStat.clear();
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
				case Lang.t("SHOP_MENU_BTN"):
						Config.application.startPage('shop');
						break;
				case Lang.t("MY_ACHIEVEMENTS"):
						new OpenRewardLevelCommand(UserProfile.instance).execute();
						break;
				case Lang.t("USERS_TOP"):
						Config.application.startPage("top");
						break;
				case Lang.t("ABOUT_GAME"):
						Config.application.startPage("about");
						break;
				case Lang.t('TUTORIAL_BTN'):
						Config.application.startGame(new TutorialLevelDef())
						break;
			}
		}

		// для тьюториала
		public function get startGameButton():OrangeButton
		{
			return buttons[0];
		}

		// для тьюториала
		public function get rewardButton():OrangeButton
		{
			for each(var b:OrangeButton in buttons)
				if(b.label == Lang.t('MY_ACHIEVEMENTS'))
					return b;
			disableButtons(false);
			return null;
		}

		// для тьюториала
		public function get levelsButton():OrangeButton
		{
			for each(var b:OrangeButton in buttons)
				if(b.label == Lang.t('LEVEL_SELECTION'))
					return b;
			disableButtons(false);
			return null;
		}

		// для тьюториала
		public function disableButtons(disable:Boolean = true):void
		{
			for each(var b:OrangeButton in buttons)
				b.enabled = !disable;
		}

		// для тьюториала
		public function getFriendBar():FriendBar
		{
			return friendBar;
		}
	}
}