package com.somewater.rabbit.application.windows
{
	import com.somewater.display.Window;
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
		
		private var soundButton:SoundSwitchButton;
		private var musicButton:SoundSwitchButton;
		
		private var soundSlider:SlideBar;
		private var musicSlider:SlideBar;
		
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
			
			soundButton = new SoundSwitchButton("sound");
			soundButton.x = restartLevelButton.x;
			soundButton.y = restartLevelButton.y + restartLevelButton.height + 25;
			addChild(soundButton);
			soundButton.addEventListener(MouseEvent.CLICK, onSoundButtonClick);
			
			musicButton = new SoundSwitchButton("music");
			musicButton.x = soundButton.x;
			musicButton.y = soundButton.y + soundButton.height + 15;
			addChild(musicButton);
			musicButton.addEventListener(MouseEvent.CLICK, onMusicButtonClick);
			
			soundSlider = new SlideBar();
			soundSlider.value = Config.application.sound;
			soundSlider.x = restartLevelButton.x + restartLevelButton.width - soundSlider.width;
			soundSlider.y = soundButton.y + soundButton.height * 0.5;
			soundSlider.addEventListener(Event.CHANGE, onSoundChange);
			addChild(soundSlider);
			soundSlider.enabled = soundButton.enabled = Config.application.soundEnabled;
			
			musicSlider = new SlideBar();
			musicSlider.value = Config.application.music;
			musicSlider.x = soundSlider.x;
			musicSlider.y = musicButton.y + musicButton.height * 0.5;
			musicSlider.addEventListener(Event.CHANGE, onMusicChange);
			addChild(musicSlider);
			musicSlider.enabled = musicButton.enabled = Config.application.musicEnabled;
			
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
			soundButton.removeEventListener(MouseEvent.CLICK, onSoundButtonClick);
			musicButton.removeEventListener(MouseEvent.CLICK, onMusicButtonClick);
			soundSlider.removeEventListener(Event.CHANGE, onSoundChange);
			musicSlider.removeEventListener(Event.CHANGE, onMusicChange);
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
		
		
		private function onSoundButtonClick(e:Event):void
		{
			Config.application.soundEnabled = !Config.application.soundEnabled;
			soundSlider.enabled = soundButton.enabled = Config.application.soundEnabled;
		}
		
		private function onMusicButtonClick(e:Event):void
		{
			Config.application.musicEnabled = !Config.application.musicEnabled;
			musicSlider.enabled = musicButton.enabled = Config.application.musicEnabled;
		}
		
		private function onSoundChange(e:Event):void
		{
			Config.application.sound = soundSlider.value;
		}
		
		private function onMusicChange(e:Event):void
		{
			Config.application.music = musicSlider.value;
		}
	}
}