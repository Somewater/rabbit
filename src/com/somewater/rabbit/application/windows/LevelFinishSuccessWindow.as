package com.somewater.rabbit.application.windows {
	import com.somewater.rabbit.storage.Config;
	import com.somewater.rabbit.storage.LevelInstanceDef;
	import com.somewater.rabbit.storage.Lib;

	import flash.events.Event;

	/**
	 * Появляется после успешного прохождения уровня.
	 * СОдержит различные контролы, описывающие пар-ры прохождения уровня, а также бонусы
	 * Закрытие или нажатие кнопки ОК ведет к старту следующего непройденного уровня
	 */
	public class LevelFinishSuccessWindow extends LevelSwitchWindow{
		public function LevelFinishSuccessWindow(levelInstance:LevelInstanceDef) {
			this.levelInstance = levelInstance;
			this.level = levelInstance.levelDef;
			super();
		}

		override public function clear():void {
			super.clear();
		}

		override protected function createContent():void {
			createIcon(Lib.createMC("interface.LevelStarIcon_success"))
		}


		override protected function onWindowClosed(e:Event = null):void {
			Config.application.startGame();
		}
	}
}
