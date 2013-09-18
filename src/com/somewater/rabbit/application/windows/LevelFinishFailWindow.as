package com.somewater.rabbit.application.windows {
	import com.somewater.rabbit.Stat;
	import com.somewater.rabbit.application.AppServerHandler;
	import com.somewater.rabbit.application.buttons.GreenButton;
	import com.somewater.rabbit.application.shop.BuyMoneyWindow;
	import com.somewater.rabbit.storage.ConfManager;
	import com.somewater.rabbit.storage.Config;
	import com.somewater.rabbit.storage.LevelDef;
	import com.somewater.rabbit.storage.LevelInstanceDef;
	import com.somewater.rabbit.storage.Lib;
	import com.somewater.rabbit.storage.UserProfile;
	import com.somewater.storage.Lang;
	import com.somewater.text.Hint;

	import flash.events.Event;
	import flash.events.MouseEvent;

	/**
	 * Появляется при неуспешном завершении уровня (проигрыше)
	 * Содержит текст (поясняющий причину проигрыша), а также картинку - визуальное пояснение
	 * Нажатие кнопки ОК или закрытие окна запускает уровень еще раз
	 */
	public class LevelFinishFailWindow extends LevelSwitchWindow{

		private var buyContinueBtn:GreenButton;
		private var cost:int;

		public function LevelFinishFailWindow(levelInstance:LevelInstanceDef) {
			this.levelInstance = levelInstance;
			this.level = levelInstance.levelDef || Config.game.level;
			super();

			okButton.icon = Lib.createMC('interface.IconRestart');
			okButton.label = Lang.t("BUTTON_RESTART_LEVEL");

			buyContinueBtn = new GreenButtonWithRightIcon();
			buyContinueBtn.ICON_PADDING = 15;
			buyContinueBtn.icon = Lib.createMC('interface.MoneyIcon');
			buyContinueBtn.addEventListener(MouseEvent.MOUSE_DOWN, onContinueClicked);
			if(levelInstance.finalFlag == LevelInstanceDef.LEVEL_FATAL_LIFE){
				cost = ConfManager.instance.getNumber('CONTINUE_LIFE_COST');
				buyContinueBtn.htmlLabel = Lang.t("ВОССТАНОВИТЬ ЖИЗНЬ ЗА <font size='18'>{cost}</font>", {cost: cost})
				Hint.bind(buyContinueBtn, "Будет восстановлена жизнь и добавлена на несколько секунд защита от врагов");
			} else if (levelInstance.finalFlag == LevelInstanceDef.LEVEL_FATAL_CARROT){
				cost = ConfManager.instance.getNumber('CONTINUE_CARROTS_COST');
				buyContinueBtn.htmlLabel = Lang.t("ВОССТАНОВИТЬ МОРКОВКИ ЗА <font size='18'>{cost}</font>", {cost: cost})
				Hint.bind(buyContinueBtn, "Все морковки, которые были съедены воронами, снова вырастут");
			} else if (levelInstance.finalFlag == LevelInstanceDef.LEVEL_FATAL_TIME){
				cost = ConfManager.instance.getNumber('CONTINUE_TIME_COST');
				buyContinueBtn.htmlLabel = Lang.t("ВОССТАНОВИТЬ ВРЕМЯ ЗА <font size='18'>{cost}</font>", {cost: cost})
				Hint.bind(buyContinueBtn, Lang.t("Будет добавлено {sec} секунд времени", {sec: 30}));
			}
			addChild(buyContinueBtn);

			okButton.width = 150;
			buyContinueBtn.width = 300;
			const BTN_PADDING:int = 60;

			okButton.y = buyContinueBtn.y = this.height - 80;
			buyContinueBtn.x = (this.width - buyContinueBtn.width - BTN_PADDING - okButton.width) * 0.5;
			okButton.x = buyContinueBtn.x + buyContinueBtn.width + BTN_PADDING;
		}

		override public function clear():void {
			super.clear();
			buyContinueBtn.clear();
			Hint.removeHint(buyContinueBtn);
			buyContinueBtn.removeEventListener(MouseEvent.MOUSE_DOWN, onContinueClicked);
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
			clearLevel();
			super.onCloseBtnClick(e);
			// открываем страницу левелов
			Config.application.startPage('levels');
		}


		override protected function onWindowClosed(e:Event = null):void {
			// стартуем тот же уровень, что был в игре на момент старта окна
			clearLevel();
			var level:LevelDef = this.level;
			if(UserProfile.instance.canSpendEnergy()){
				Config.application.startGame(level);
			}else{
				new NeedMoreEnergyWindow(function():void{
					Config.application.startGame(level);
				}, function():void {
					Config.application.startPage("main_menu");
				})
			}
		}

		private function onContinueClicked(event:Event = null):void {
			if(event)
				event.stopImmediatePropagation();
			BuyMoneyWindow.withMoney(this.cost, function():void{
				continueLevel();
			})
		}

		private function continueLevel():void {
			Config.application.showSlash(0);
			AppServerHandler.instance.buyLevelContinue(levelInstance.finalFlag, function(response:Object){
				Config.application.hideSplash();
				Config.game.continueLevel(levelInstance);
				close();
			}, function(response:Object){
				Config.application.hideSplash();
				Config.application.message("Ошибка покупки");
				Config.stat(Stat.ERROR_MONEY_DISCARDING);
				close();
				Config.application.startPage('levels');
			})
		}

		private function clearLevel():void {
			Config.application.addFinishedLevel(levelInstance);
			Config.game.finishLevel(levelInstance);
		}
	}
}

import com.somewater.rabbit.application.buttons.GreenButton;

class GreenButtonWithRightIcon extends GreenButton{

	override protected function resize():void {
		super.resize();

		if(_icon)
		{
			textField.x = (_width - _icon.width - ICON_PADDING - textField.width) * 0.5;
			_icon.x = textField.x + textField.textWidth + ICON_PADDING
			_icon.y = (_height - _icon.height) * 0.5;
		}
	}
}
