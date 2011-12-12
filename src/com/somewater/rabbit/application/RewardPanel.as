package com.somewater.rabbit.application {
	import com.somewater.control.IClear;
	import com.somewater.rabbit.storage.Lib;
	import com.somewater.storage.Lang;
	import com.somewater.text.EmbededTextField;

	import flash.display.DisplayObject;

	import flash.display.Sprite;

	public class RewardPanel extends Sprite implements IClear{

		private var bonusIcons:Array = [];

		public function RewardPanel(rewards:Array) {
			// создание бонусов. если надо
			var bonusGround:DisplayObject = Lib.createMC('interface.LevelSuccessBonusesGround');
			addChild(bonusGround);
			
			var bonusHolder:Sprite = new Sprite();
			addChild(bonusHolder);
			
			var bonusesTitle:EmbededTextField = new EmbededTextField(null, 0xDB661B,14);
			bonusesTitle.text = Lang.t('LEVEL_BONUSES_TITLE');
			bonusesTitle.x = (bonusGround.width - bonusesTitle.width) * 0.5;
			bonusesTitle.y = bonusGround.y - 25;
			addChild(bonusesTitle);
			
			var bonusLength:int = rewards.length;
			var BONUS_HOLDER_WIDTH:int = 450;
			var BONUS_HOLDER_HEIGHT:int = 123;
			var bonusPadding:int = (BONUS_HOLDER_WIDTH - bonusLength * RewardIcon.WIDTH) / (bonusLength + 1);
			var nextX:int = bonusPadding;
			for each(var reward:* in rewards)
			{
				var bonusIcon:RewardIcon = new RewardIcon(reward);
				bonusIcon.x = nextX;
				bonusIcon.y = (BONUS_HOLDER_HEIGHT - RewardIcon.HEIGHT) * 0.5;
				bonusHolder.addChild(bonusIcon);
				bonusIcons.push(bonusIcon);
				nextX += RewardIcon.WIDTH + bonusPadding;
			}
		}

		public function clear():void
		{
			if(bonusIcons)
				for(var i:int = 0;i<bonusIcons.length;i++)
					IClear(bonusIcons[i]).clear();
			bonusIcons = null;
		}
	}
}
