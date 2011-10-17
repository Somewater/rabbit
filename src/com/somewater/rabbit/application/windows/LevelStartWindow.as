package com.somewater.rabbit.application.windows {
	import com.somewater.rabbit.storage.Config;
	import com.somewater.rabbit.storage.LevelDef;
	import com.somewater.rabbit.storage.Lib;
	import com.somewater.storage.Lang;
	import com.somewater.text.EmbededTextField;

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
			createIcon(Lib.createMC("interface.LevelStarIcon_number"));
			var iconLevelNumber:EmbededTextField = new EmbededTextField(null, 0xD8F776, 85, false, false, false, false, "center")
			iconLevelNumber.x = 6;
			iconLevelNumber.y = 34;
			iconLevelNumber.width = 155;
			iconLevelNumber.text = level.number.toString();
			starIcon.addChild(iconLevelNumber);
			if(level.number > 9) starIcon.x = -40;
			createTextAndImage(levelToString(level), level.description, level.image);
		}


		override protected function onWindowClosed(e:Event = null):void {
			Config.game.start();
		}
	}
}
