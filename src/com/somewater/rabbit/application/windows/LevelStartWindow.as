package com.somewater.rabbit.application.windows {
	import com.somewater.rabbit.storage.Config;
	import com.somewater.rabbit.storage.LevelDef;
	import com.somewater.rabbit.storage.Lib;
	import com.somewater.storage.Lang;
	import com.somewater.text.EmbededTextField;

	import flash.events.Event;
	import flash.events.MouseEvent;

	/**
	 * ПОявляется при старте уровня. СОдержит описание уровня, картинку, кнопку ОК
	 * При нажатии кнопки ОК или закрытии окна, уровень снимается с паузы
	 */
	public class LevelStartWindow extends LevelSwitchWindow{

		/**
		 * Счетчик стартов в пределах сессии. Не показываем окно более 3х раз на один уровень
		 */
		private static var startStat:Array = [];

		public function LevelStartWindow(level:LevelDef) {
 			this.level = level;
			super();

			if(startStat[level.number] == null)
				startStat[level.number] = 1;
			else
				startStat[level.number]++;

			if(startStat[level.number] > 3 && startStat['last_level'] == level.number)
			{
				// окно самозакрывается, чтобы не надоедать
				close();
			}
			else
			{
				// если это окно стартовало, значит надо запаузить игру.
				// Однако, даем игре тикнуть 3 раза, чтобы инициализовались все менеджеры
				Config.callLater(Config.game.pause, null, 2);
			}

			startStat['last_level'] = level.number;
		}

		override protected function onCloseBtnClick(e:MouseEvent):void {
			onWindowClosed();
			super.onCloseBtnClick(e);
		}

		override public function clear():void {
			super.clear();
		}

		override protected function createContent():void {
			createIcon(Lib.createMC("interface.LevelStarIcon_number"));
			var iconLevelNumber:EmbededTextField = new EmbededTextField(null, 0xD8F776, 80, false, false, false, false, "center")
			iconLevelNumber.x = 6;
			iconLevelNumber.y = 37;
			iconLevelNumber.width = 155;
			iconLevelNumber.text = level.number.toString();
			starIcon.addChild(iconLevelNumber);
			createTextAndImage(levelToString(level), level.description, level.image);
		}


		override protected function onWindowClosed(e:Event = null):void {
			Config.game.start();
		}
	}
}
