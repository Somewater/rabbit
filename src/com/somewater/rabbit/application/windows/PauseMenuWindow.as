package com.somewater.rabbit.application.windows
{
	import com.somewater.display.Window;
	import com.somewater.rabbit.application.AudioControls;
	import com.somewater.rabbit.application.OrangeButton;
	import com.somewater.rabbit.application.buttons.SlideBar;
	import com.somewater.rabbit.application.buttons.SoundSwitchButton;
	import com.somewater.rabbit.storage.Config;
	import com.somewater.rabbit.storage.LevelDef;
	import com.somewater.rabbit.storage.LevelInstanceDef;
	import com.somewater.storage.Lang;
	
	import flash.events.Event;
	import flash.events.MouseEvent;

	public class PauseMenuWindow extends Window
	{
		private var gotoMainMenuButton:OrangeButton;
		private var restartLevelButton:OrangeButton;
		
		private var audioControls:AudioControls;
		
		public function PauseMenuWindow()
		{
			super("", Lang.t("PAUSE"), null, [])
			setSize(270, 320);
			
			gotoMainMenuButton = new OrangeButton();
			gotoMainMenuButton.setSize(180, 32);
			gotoMainMenuButton.label = Lang.t("BUTTON_GOTO_MAIN_MENU");
			gotoMainMenuButton.x = (width - gotoMainMenuButton.width) * 0.5;
			gotoMainMenuButton.y = 70;
			addChild(gotoMainMenuButton);
			gotoMainMenuButton.addEventListener(MouseEvent.CLICK, onGotoMainMenuClick);
			
			restartLevelButton = new OrangeButton();
			restartLevelButton.setSize(180, 32);
			restartLevelButton.label = Lang.t("BUTTON_RESTART_LEVEL");
			restartLevelButton.x = (width - restartLevelButton.width) * 0.5;
			restartLevelButton.y = gotoMainMenuButton.y + gotoMainMenuButton.height + 25;
			addChild(restartLevelButton);
			restartLevelButton.addEventListener(MouseEvent.CLICK, onRestartLevelClick);
			
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
			
			gotoMainMenuButton.removeEventListener(MouseEvent.CLICK, onGotoMainMenuClick);
			restartLevelButton.removeEventListener(MouseEvent.CLICK, onRestartLevelClick);
			audioControls.clear();
		}
		
		private function onGotoMainMenuClick(e:Event):void
		{
			close();
			
			Config.game.finishLevel(LevelInstanceDef.DUMMY_FATAL_LEVEL, true);
			Config.application.startPage("main_menu");
		}
		
		
		private function onRestartLevelClick(e:Event):void
		{
			close();
			
			var level:LevelDef = Config.game.level;
			Config.game.finishLevel(LevelInstanceDef.DUMMY_FATAL_LEVEL, true);
			Config.application.startGame(level);
		}
	}
}