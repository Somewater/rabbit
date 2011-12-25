package com.somewater.rabbit.application {
	import com.somewater.control.IClear;
	import com.somewater.rabbit.application.buttons.SlideBar;
	import com.somewater.rabbit.application.buttons.SoundSwitchButton;
	import com.somewater.rabbit.storage.Config;

	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;

	public class AudioControls extends Sprite implements IClear{

		private var soundButton:SoundSwitchButton;
		private var musicButton:SoundSwitchButton;

		private var soundSlider:SlideBar;
		private var musicSlider:SlideBar;

		public function AudioControls(yOffset:int = 25) {
			soundButton = new SoundSwitchButton("sound");
			addChild(soundButton);
			soundButton.addEventListener(MouseEvent.CLICK, onSoundButtonClick);

			musicButton = new SoundSwitchButton("music");
			musicButton.x = soundButton.x;
			musicButton.y = soundButton.y + soundButton.height + yOffset;
			addChild(musicButton);
			musicButton.addEventListener(MouseEvent.CLICK, onMusicButtonClick);

			soundSlider = new SlideBar();
			soundSlider.value = Config.application.sound;
			soundSlider.x = 180 - soundSlider.width;
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
		}

		public function clear():void {
			soundButton.removeEventListener(MouseEvent.CLICK, onSoundButtonClick);
			musicButton.removeEventListener(MouseEvent.CLICK, onMusicButtonClick);
			soundSlider.removeEventListener(Event.CHANGE, onSoundChange);
			musicSlider.removeEventListener(Event.CHANGE, onMusicChange);
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
