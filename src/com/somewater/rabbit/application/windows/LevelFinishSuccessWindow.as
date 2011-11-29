package com.somewater.rabbit.application.windows {
	import com.somewater.control.IClear;
	import com.somewater.rabbit.application.GameGUI;
	import com.somewater.rabbit.application.LevelRewardIcon;
	import com.somewater.rabbit.storage.Config;
	import com.somewater.rabbit.storage.LevelInstanceDef;
	import com.somewater.rabbit.storage.Lib;
	import com.somewater.rabbit.storage.RewardDef;
	import com.somewater.rabbit.storage.RewardInstanceDef;
	import com.somewater.rabbit.storage.UserProfile;
	import com.somewater.storage.Lang;
	import com.somewater.text.EmbededTextField;
	
	import flash.display.DisplayObject;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.ColorTransform;

	/**
	 * Появляется после успешного прохождения уровня.
	 * СОдержит различные контролы, описывающие пар-ры прохождения уровня, а также бонусы
	 * Закрытие или нажатие кнопки ОК ведет к старту следующего непройденного уровня
	 */
	public class LevelFinishSuccessWindow extends LevelSwitchWindow{
		private var core:*;
		private var bonusIcons:Array = [];

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
			for each(var b:IClear in bonusIcons)
				b.clear();
			bonusIcons = null;
		}

		override protected function createContent():void {
			var needCreateRewards:Boolean = levelInstance.rewards.length;

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
			levelSuccTitle.y = 16+ (needCreateRewards ? 0 : 20);
			levelSuccTitle.x = (width - levelSuccTitle.width) * 0.5;
			addChild(levelSuccTitle);

			var levelSuccDesc:EmbededTextField = new EmbededTextField(null, 0xDB661B, 14);
			levelSuccDesc.text = Lang.t(levelInstance.stars == 1 ? 'LEVEL_COMPLETED_MIN' :
							(levelInstance.stars == 2 ? 'LEVEL_COMPLETED_MID' :
							(levelInstance.stars == 3 ? 'LEVEL_COMPLETED_MAX' : 'LEVEL_COMPLETED_UNDEFENED')));
			levelSuccDesc.y = 46+ (needCreateRewards ? 0 : 20);
			levelSuccDesc.x = (width - levelSuccDesc.width) * 0.5;
			addChild(levelSuccDesc);

			core = Lib.createMC("interface.LevelSuccessWindowContent");
			core.x = 74;
			core.y = 72 + (needCreateRewards ? 0 : 50);
			addChild(core);

			var spendedTime:EmbededTextField = new EmbededTextField(Config.FONT_SECONDARY, 0x2F4015, 12, true, false,false, false, 'center');
			spendedTime.x = 0;
			spendedTime.y = 0;
			spendedTime.width = 161;
			core.addChild(spendedTime);
			spendedTime.text = Lang.t('LEVEL_SPENDED_TIME');

			var spendedTimeCounter:EmbededTextField = new EmbededTextField(Config.FONT_SECONDARY, 0x124D18, 21, true, false,false, false, 'center');
			spendedTimeCounter.x = 0;
			spendedTimeCounter.y = 32;
			spendedTimeCounter.width = 161;
			core.addChild(spendedTimeCounter);
			spendedTimeCounter.text = GameGUI.secondsToFormattedTime(levelInstance.timeSpended * 0.001);

			var addedScore:EmbededTextField = new EmbededTextField(Config.FONT_SECONDARY, 0x2F4015, 12, true, false,false, false, 'center');
			addedScore.x = 161;
			addedScore.y = 0;
			addedScore.width = 161;
			core.addChild(addedScore);
			addedScore.text = Lang.t('LEVEL_OBTAINED_SCORE');

			var addedScoreCounter:EmbededTextField = new EmbededTextField(Config.FONT_SECONDARY, 0x675510, 18, true, false,false, false, 'center');
			addedScoreCounter.x = 199;
			addedScoreCounter.y = 34;
			addedScoreCounter.width = 58;
			core.addChild(addedScoreCounter);
			addedScoreCounter.text = levelInstance.carrotHarvested.toString();

			var ratingValue:EmbededTextField = new EmbededTextField(Config.FONT_SECONDARY, 0x2F4015, 12, true, false,false, false, 'center');
			ratingValue.x = 304;
			ratingValue.y = 0;
			ratingValue.width = 161;
			core.addChild(ratingValue);
			ratingValue.text = Lang.t('LEVEL_PROGRESS_RATING');

			for (var i:int = 1; i < 4; i++) {
				if(levelInstance.stars >= i)
					DisplayObject(core['carrot' + i]).alpha = 1;
				else
					DisplayObject(core['carrot' + i]).alpha = 0.3;
			}

			if(needCreateRewards)
			{
				// создание бонусов. если надо
				var bonusGround:DisplayObject = Lib.createMC('interface.LevelSuccessBonusesGround');
				bonusGround.y = 195;
				bonusGround.x = (this.width - bonusGround.width) * 0.5;
				addChild(bonusGround);

				var bonusHolder:Sprite = new Sprite();
				bonusHolder.x = bonusGround.x;
				bonusHolder.y = bonusGround.y;
				addChild(bonusHolder);

				var bonusesTitle:EmbededTextField = new EmbededTextField(null, 0xDB661B,14);
				bonusesTitle.text = Lang.t('LEVEL_BONUSES_TITLE');
				bonusesTitle.x = (this.width - bonusesTitle.width) * 0.5;
				bonusesTitle.y = bonusGround.y - 25;
				addChild(bonusesTitle);

				var bonusLength:int = levelInstance.rewards.length;
				var BONUS_HOLDER_WIDTH:int = 450;
				var BONUS_HOLDER_HEIGHT:int = 123;
				var bonusPadding:int = (BONUS_HOLDER_WIDTH - bonusLength * LevelRewardIcon.WIDTH) / (bonusLength + 1);
				var nextX:int = bonusPadding;
				for each(var reward:RewardInstanceDef in levelInstance.rewards)
				{
					var bonusIcon:LevelRewardIcon = new LevelRewardIcon(levelInstance, reward);
					bonusIcon.x = nextX;
					bonusIcon.y = (BONUS_HOLDER_HEIGHT - LevelRewardIcon.HEIGHT) * 0.5;
					bonusHolder.addChild(bonusIcon);
					bonusIcons.push(bonusIcon);
					nextX += LevelRewardIcon.WIDTH + bonusPadding;
				}
			}
		}


		override protected function onWindowClosed(e:Event = null):void {
			// стартуем следующий непройденный уровень, если мы только что прошли новый (ранее непройденный) уровень
			if(UserProfile.instance.levelNumber - 1 == level.number
					&& Config.application.getLevelByNumber(UserProfile.instance.levelNumber) != null)  // и еще есть непройденные уровни
				Config.application.startGame();
			// иначе переходим в меню уровней
			else
				Config.application.startPage('levels');
		}
	}
}
