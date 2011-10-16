package com.somewater.rabbit.application.windows {
	import com.somewater.rabbit.storage.Config;
	import com.somewater.rabbit.storage.LevelInstanceDef;

	import flash.events.Event;

	/**
	 * Появляется при неуспешном завершении уровня (проигрыше)
	 * Содержит текст (поясняющий причину проигрыша), а также картинку - визуальное пояснение
	 * Нажатие кнопки ОК или закрытие окна запускает уровень еще раз
	 */
	public class LevelFinishFailWindow extends LevelSwitchWindow{
		public function LevelFinishFailWindow(levelInstance:LevelInstanceDef) {
			this.levelInstance = levelInstance;
			this.level = levelInstance.levelDef;
			super();
		}

		override public function clear():void {
			super.clear();
		}

		override protected function createContent():void {
			var failText:String = levelInstance.finalFlag + "_DESC";
			var failImage:String =
					(levelInstance.finalFlag == LevelInstanceDef.LEVEL_FATAL_CARROT ? "LevelFatalCarrot"
					:(levelInstance.finalFlag == LevelInstanceDef.LEVEL_FATAL_LIFE ? "LevelFatalLife"
					:(levelInstance.finalFlag == LevelInstanceDef.LEVEL_FATAL_TIME ? "LevelFatalTime" : null)));
			createTextAndImage(levelToString(level), failText, failImage);
		}


		override protected function onWindowClosed(e:Event = null):void {
			Config.application.startGame();
		}
	}
}
