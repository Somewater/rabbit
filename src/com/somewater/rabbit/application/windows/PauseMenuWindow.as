package com.somewater.rabbit.application.windows
{
	import com.somewater.display.Window;
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
	
	import flash.events.Event;
	import flash.events.MouseEvent;

	public class PauseMenuWindow extends Window
	{
		private var gotoMainMenuButton:OrangeButton;
		private var gotoSelectLevelButton:OrangeButton;
		private var restartLevelButton:OrangeButton;
		
		private var audioControls:AudioControls;
		
		public function PauseMenuWindow()
		{
			super("", Lang.t("PAUSE"), null, [])
			setSize(270, 390);
			
			gotoMainMenuButton = new OrangeButton();
			gotoMainMenuButton.setSize(180, 32);
			gotoMainMenuButton.label = Lang.t("BUTTON_GOTO_MAIN_MENU");
			gotoMainMenuButton.x = (width - gotoMainMenuButton.width) * 0.5;
			gotoMainMenuButton.y = 70;
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
		}
		
		override public function clear():void
		{
			super.clear();
			
			if(gotoMainMenuButton)
				gotoMainMenuButton.removeEventListener(MouseEvent.CLICK, onGotoMainMenuClick);
			if(gotoSelectLevelButton)
				gotoSelectLevelButton.removeEventListener(MouseEvent.CLICK, onSelectLevelClick);
			restartLevelButton.removeEventListener(MouseEvent.CLICK, onRestartLevelClick);
			audioControls.clear();
		}
		
		private function onGotoMainMenuClick(e:Event):void
		{
			close();
			
			Config.game.finishLevel(LevelInstanceDef.DUMMY_FATAL_LEVEL, true);
			Config.application.startPage("main_menu");
		}

		private function onSelectLevelClick(event:Event):void
		{
			close();

			Config.game.finishLevel(LevelInstanceDef.DUMMY_FATAL_LEVEL, true);
			Config.application.startPage("levels");
		}
		
		
		private function onRestartLevelClick(e:Event):void
		{
			close();
			
			new RestartLevelCommand().execute();
		}
	}
}