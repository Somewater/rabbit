package com.somewater.rabbit.application.windows {
	import com.somewater.rabbit.storage.Config;
	import com.somewater.rabbit.storage.LevelDef;
	import com.somewater.rabbit.storage.LevelInstanceDef;
	import com.somewater.rabbit.storage.Lib;
	import com.somewater.rabbit.storage.UserProfile;
	import com.somewater.storage.Lang;

	import flash.events.Event;
	import flash.events.MouseEvent;

	/**
	 * Появляется при неуспешном завершении уровня (проигрыше)
	 * Содержит текст (поясняющий причину проигрыша), а также картинку - визуальное пояснение
	 * Нажатие кнопки ОК или закрытие окна запускает уровень еще раз
	 */
	public class LevelFinishFailWindow extends LevelSwitchWindow{

		public function LevelFinishFailWindow(levelInstance:LevelInstanceDef) {
			this.levelInstance = levelInstance;
			this.level = levelInstance.levelDef || Config.game.level;
			super();
		}

		override public function clear():void {
			super.clear();
		}

		override protected function createContent():void {
			createIcon(Lib.createMC("interface.LevelStarIcon_fail"));
			var failText:String = Lang.t(levelInstance.finalFlag + "_DESC");
			var failImage:String =
					(levelInstance.finalFlag == LevelInstanceDef.LEVEL_FATAL_CARROT ? "interface.LevelFailIcon_carrot"
					:(levelInstance.finalFlag == LevelInstanceDef.LEVEL_FATAL_LIFE ? "interface.LevelFailIcon_life"
					:(levelInstance.finalFlag == LevelInstanceDef.LEVEL_FATAL_TIME ? "interface.LevelFailIcon_time" : null)));
			createTextAndImage(levelToString(level), failText, failImage);
		}

		override protected function onCloseBtnClick(e:MouseEvent):void {
			super.onCloseBtnClick(e);
			// открываем страницу левелов
			Config.application.startPage('levels');
		}


		override protected function onWindowClosed(e:Event = null):void {
			// стартуем тот же уровень, что был в игре на момент старта окна
			if(UserProfile.instance.canSpendEnergy()){
				UserProfile.instance.spendEnergy();
				Config.application.startGame(level);
			}else{
				Config.application.message("NEED_MORE_ENERGY_ERROR");
			}
		}
	}
}
