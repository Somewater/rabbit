package com.somewater.rabbit.application.windows
{
	import com.somewater.display.Window;
	import com.somewater.rabbit.Stat;
	import com.somewater.rabbit.application.AudioControls;
	import com.somewater.rabbit.application.OrangeButton;
	import com.somewater.rabbit.application.buttons.SlideBar;
	import com.somewater.rabbit.application.buttons.SoundSwitchButton;
	import com.somewater.rabbit.application.commands.RestartLevelCommand;
	import com.somewater.rabbit.storage.Config;
	import com.somewater.rabbit.storage.LevelDef;
	import com.somewater.rabbit.storage.LevelInstanceDef;
	import com.somewater.rabbit.storage.Lib;
	import com.somewater.storage.Lang;
	import com.somewater.text.EmbededTextField;

	import flash.events.Event;
	import flash.events.MouseEvent;

	public class PauseMenuWindow extends Window
	{
		private var backToTheGame:OrangeButton;
		private var gotoMainMenuButton:OrangeButton;
		private var gotoSelectLevelButton:OrangeButton;
		private var restartLevelButton:OrangeButton;
		
		private var audioControls:AudioControls;
		
		public function PauseMenuWindow()
		{
			super("", null, null, [])
			setSize(270, 430);

			var title:EmbededTextField = new EmbededTextField(null, 0xDB661B, 20);
			title.text = Lang.t('PAUSE').toUpperCase();
			title.x = (this.width - title.width) * 0.5 - 5;
			title.y = 20;
			addChild(title);

			backToTheGame = new OrangeButton();
			backToTheGame.setSize(180, 32);
			backToTheGame.label = Lang.t("BACK_TO_THE_GAME_BTN");
			backToTheGame.x = (width - backToTheGame.width) * 0.5;
			backToTheGame.y = 70;
			addChild(backToTheGame);
			backToTheGame.addEventListener(MouseEvent.MOUSE_DOWN, onBackToTheGameClick);
			backToTheGame.icon = Lib.createMC('interface.IconPlay');

			gotoMainMenuButton = new OrangeButton();
			gotoMainMenuButton.setSize(180, 32);
			gotoMainMenuButton.label = Lang.t("BUTTON_GOTO_MAIN_MENU");
			gotoMainMenuButton.x = (width - gotoMainMenuButton.width) * 0.5;
			gotoMainMenuButton.y = backToTheGame.y + backToTheGame.height + 25;
			addChild(gotoMainMenuButton);
			gotoMainMenuButton.addEventListener(MouseEvent.CLICK, onGotoMainMenuClick);
			gotoMainMenuButton.icon = Lib.createMC('interface.IconHome');

			gotoSelectLevelButton = new OrangeButton();
			gotoSelectLevelButton.setSize(180, 32);
			gotoSelectLevelButton.label = Lang.t("LEVEL_SELECTION");
			gotoSelectLevelButton.x = (width - gotoSelectLevelButton.width) * 0.5;
			gotoSelectLevelButton.y = gotoMainMenuButton ? gotoMainMenuButton.y + gotoMainMenuButton.height + 25 : 70;
			addChild(gotoSelectLevelButton);
			gotoSelectLevelButton.addEventListener(MouseEvent.CLICK, onSelectLevelClick);
			gotoSelectLevelButton.icon = Lib.createMC('interface.IconLevels');
			
			restartLevelButton = new OrangeButton();
			restartLevelButton.setSize(180, 32);
			restartLevelButton.label = Lang.t("BUTTON_RESTART_LEVEL");
			restartLevelButton.x = (width - restartLevelButton.width) * 0.5;
			if(gotoMainMenuButton && gotoSelectLevelButton == null)
				restartLevelButton.y = gotoMainMenuButton.y + gotoMainMenuButton.height + 25;
			else if(gotoSelectLevelButton)
				restartLevelButton.y = gotoSelectLevelButton.y + gotoSelectLevelButton.height + 25;
			addChild(restartLevelButton);
			restartLevelButton.addEventListener(MouseEvent.CLICK, onRestartLevelClick);
			restartLevelButton.icon = Lib.createMC('interface.IconRestart');
			
			audioControls = new AudioControls();
			audioControls.x = restartLevelButton.x;
			audioControls.y = restartLevelButton.y + restartLevelButton.height + 25;
			addChild(audioControls);
			
			open();
			
			//////////////////
			//				//
			//	PAUSE GAME	//
			//				//
			//////////////////
			Config.game.pause();

			Config.stat(Stat.ON_PAUSE);

			closeButton.removeEventListener(MouseEvent.CLICK, onCloseBtnClick);
			closeButton.addEventListener(MouseEvent.MOUSE_DOWN, onCloseBtnClick);
		}
		
		public function simulateCloseButtonClick():void
		{
			onCloseBtnClick(new MouseEvent(MouseEvent.CLICK));
		}
		
		override protected function onCloseBtnClick(e:MouseEvent):void
		{
			//////////////////
			//				//
			//	START GAME	//
			//				//
			//////////////////
			Config.game.start();
			super.onCloseBtnClick(e);
			e.stopImmediatePropagation();
		}
		
		override public function clear():void
		{
			super.clear();

			if(backToTheGame)
				backToTheGame.removeEventListener(MouseEvent.MOUSE_DOWN, onBackToTheGameClick);
			if(gotoMainMenuButton)
				gotoMainMenuButton.removeEventListener(MouseEvent.CLICK, onGotoMainMenuClick);
			if(gotoSelectLevelButton)
				gotoSelectLevelButton.removeEventListener(MouseEvent.CLICK, onSelectLevelClick);
			restartLevelButton.removeEventListener(MouseEvent.CLICK, onRestartLevelClick);
			audioControls.clear();
			closeButton.removeEventListener(MouseEvent.MOUSE_DOWN, onCloseBtnClick);
		}

		private function onBackToTheGameClick(e:MouseEvent):void
		{
			onCloseBtnClick(e);
		}
		
		private function onGotoMainMenuClick(e:Event):void
		{
			close();
			
			Config.game.finishLevel(LevelInstanceDef.DUMMY_FATAL_LEVEL);
			Config.application.startPage("main_menu");
		}

		private function onSelectLevelClick(event:Event):void
		{
			close();

			Config.game.finishLevel(LevelInstanceDef.DUMMY_FATAL_LEVEL);
			Config.application.startPage("levels");
		}
		
		
		private function onRestartLevelClick(e:Event):void
		{
			close();
			
			new RestartLevelCommand().execute();
		}
	}
}