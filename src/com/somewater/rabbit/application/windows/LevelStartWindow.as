package com.somewater.rabbit.application.windows {
	import com.somewater.rabbit.storage.Config;
	import com.somewater.rabbit.storage.LevelDef;
	import com.somewater.storage.Lang;

	import flash.events.Event;

	/**
	 * ПОявляется при старте уровня. СОдержит описание уровня, картинку, кнопку ОК
	 * При нажатии кнопки ОК или закрытии окна, уровень снимается с паузы
	 */
	public class LevelStartWindow extends LevelSwitchWindow{
		public function LevelStartWindow(level:LevelDef) {
			this.level = level;
			super();
		}

		override public function clear():void {
			super.clear();
		}

		override protected function createContent():void {
			createTextAndImage(levelToString(level), level.description, level.image);
		}


		override protected function onWindowClosed(e:Event = null):void {
			Config.game.start();
		}
	}
}
