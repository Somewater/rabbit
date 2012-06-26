package com.somewater.rabbit.application.windows {
import com.somewater.controller.PopUpManager;
import com.somewater.rabbit.application.GameGUI;
	import com.somewater.rabbit.debug.EditorModule;
	import com.somewater.rabbit.storage.Config;
	import com.somewater.rabbit.storage.LevelDef;
	import com.somewater.rabbit.storage.Lib;
	import com.somewater.rabbit.xml.XmlController;
	import com.somewater.storage.Lang;
	import com.somewater.text.EmbededTextField;
	import com.somewater.text.Hint;

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

		private var coreAliensCounter:EmbededTextField;
		private var coreCarrotCounter:EmbededTextField;
		private var coreTimeCounter:EmbededTextField;
		private var core:*;

		private var aliens:int;
		private var carrot:int;
		private var time:String;

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
				// Однако, даем игре тикнуть 2 раза, чтобы инициализовались все менеджеры
				setPause();
			}

			startStat['last_level'] = level.number;
		}

		private function setPause():void
		{
			// если данное окно в текущий момент открыто, паузим игру
			if(PopUpManager.activeWindow == this)
				Config.game.pause();
		}

		override protected function onCloseBtnClick(e:MouseEvent):void {
			onWindowClosed();
			super.onCloseBtnClick(e);
		}

		override public function clear():void {
			super.clear();
			if(core)
			{
				Hint.removeHint(core.aliensIcon);
				Hint.removeHint(coreAliensCounter);

				Hint.removeHint(core.carrotIcon);
				Hint.removeHint(coreCarrotCounter);

				Hint.removeHint(core.timeIcon);
				Hint.removeHint(coreTimeCounter);
			}
		}

		override protected function createContent():void {
			createIcon(Lib.createMC("interface.LevelStarIcon_number"));
			var iconLevelNumber:EmbededTextField = new EmbededTextField(null, 0xD8F776, 80, false, false, false, false, "center")
			iconLevelNumber.x = 6;
			iconLevelNumber.y = 37;
			iconLevelNumber.width = 155;
			iconLevelNumber.text = level.number.toString();
			starIcon.addChild(iconLevelNumber);
			createTextAndImage(levelToString(level), level.name + ".\n" + level.shortDescription, level.image);

			core = Lib.createMC('interface.LevelStartCounters');
			core.x = 79;
			core.y = 258;

			coreAliensCounter = new EmbededTextField(Config.FONT_SECONDARY, 0x124D18, 20, true);
			coreAliensCounter.x = 52;
			coreAliensCounter.y = 12;
			core.addChild(coreAliensCounter);

			coreCarrotCounter = new EmbededTextField(Config.FONT_SECONDARY, 0x124D18, 20, true);
			coreCarrotCounter.x = 227;
			coreCarrotCounter.y = 12;
			core.addChild(coreCarrotCounter);

			coreTimeCounter = new EmbededTextField(Config.FONT_SECONDARY, 0x124D18, 20, true);
			coreTimeCounter.x = 405;
			coreTimeCounter.y = 12;
			core.addChild(coreTimeCounter);

			addChild(core);

			aliens = XmlController.instance.calculateAliens(level);
			carrot = XmlController.instance.calculateCarrots(level);
			time = GameGUI.secondsToFormattedTime(XmlController.instance.calculateLevelTime(level));

			coreAliensCounter.text = aliens.toString();
			coreCarrotCounter.text = carrot.toString();
			coreTimeCounter.text = time;

			Hint.bind(core.aliensIcon, aliensHint);
			Hint.bind(coreAliensCounter, aliensHint);

			Hint.bind(core.carrotIcon, carrotHint);
			Hint.bind(coreCarrotCounter, carrotHint);

			Hint.bind(core.timeIcon, timeHint);
			Hint.bind(coreTimeCounter, timeHint);
		}

		private function aliensHint():String {
			return Lang.t('LEVEL_ALIENS_ICON_HINT', {count: aliens});
		}

		private function carrotHint():String {
			return Lang.t('LEVEL_CARROT_ICON_HINT', {count: carrot});
		}

		private function timeHint():String {
			return Lang.t('LEVEL_TIME_ICON_HINT', {count: time});
		}


		override protected function onWindowClosed(e:Event = null):void {
			if(!Config.editorActive)
				Config.game.start();
			else
			{
				CONFIG::debug
				{
					EditorModule.instance.onGamePause();
				}
			}
		}
	}
}
