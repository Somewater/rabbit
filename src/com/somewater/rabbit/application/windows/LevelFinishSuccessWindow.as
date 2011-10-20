package com.somewater.rabbit.application.windows {
	import com.somewater.rabbit.storage.Config;
	import com.somewater.rabbit.storage.LevelInstanceDef;
	import com.somewater.rabbit.storage.Lib;
	import com.somewater.rabbit.storage.UserProfile;
	import com.somewater.storage.Lang;
	import com.somewater.text.EmbededTextField;

	import flash.display.DisplayObject;
	import flash.display.Shape;

	import flash.display.Sprite;

	import flash.events.Event;
	import flash.events.MouseEvent;

	/**
	 * Появляется после успешного прохождения уровня.
	 * СОдержит различные контролы, описывающие пар-ры прохождения уровня, а также бонусы
	 * Закрытие или нажатие кнопки ОК ведет к старту следующего непройденного уровня
	 */
	public class LevelFinishSuccessWindow extends LevelSwitchWindow{
		private var core:*;

		public function LevelFinishSuccessWindow(levelInstance:LevelInstanceDef) {
			this.levelInstance = levelInstance;
			this.level = levelInstance.levelDef;
			super();
		}

		override protected function onCloseBtnClick(e:MouseEvent):void {
			onWindowClosed();
			super.onCloseBtnClick(e);
		}

		override public function clear():void {
			super.clear();
		}

		override protected function createContent():void {
			var succGround:DisplayObject = Lib.createMC('interface.LevelSuccessWindow_starGround');
			succGround.x = -3;
			succGround.y = -12;

			var succGroundMask:Shape = new Shape();
			succGround.mask = succGroundMask;
			succGroundMask.graphics.beginFill(0);
			succGroundMask.graphics.drawRoundRectComplex(0,0,width,height,10,10,10,10);
			addChild(succGroundMask);
			addChild(succGround);

			createIcon(Lib.createMC("interface.LevelStarIcon_success"));

			var levelSuccTitle:EmbededTextField = new EmbededTextField(null, 0xDB661B, 20);
			levelSuccTitle.text = Lang.t('LEVEL_COMPLETED');
			levelSuccTitle.y = 16;
			levelSuccTitle.x = (width - levelSuccTitle.width) * 0.5;
			addChild(levelSuccTitle);

			var levelSuccDesc:EmbededTextField = new EmbededTextField(null, 0xDB661B, 14);
			levelSuccDesc.text = Lang.t(levelInstance.stars == 1 ? 'LEVEL_COMPLETED_MIN' :
							(levelInstance.stars == 2 ? 'LEVEL_COMPLETED_MID' :
							(levelInstance.stars == 3 ? 'LEVEL_COMPLETED_MAX' : 'LEVEL_COMPLETED_UNDEFENED')));
			levelSuccDesc.y = 46;
			levelSuccDesc.x = (width - levelSuccDesc.width) * 0.5;
			addChild(levelSuccDesc);

			core = Lib.createMC("interface.LevelSuccessWindowContent");
			core.x = 74;
			core.y = 72;
			addChild(core);
		}


		override protected function onWindowClosed(e:Event = null):void {
			// стартуем следующий непройденный уровень, если мы только что прошли новый (ранее непройденный) уровень
			if(UserProfile.instance.levelNumber == level.number)
				Config.application.startGame();
			// иначе переходим в меню уровней
			else
				Config.application.startPage('levels');
		}
	}
}
