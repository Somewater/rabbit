package com.somewater.rabbit.application {
	import com.somewater.control.IClear;
	import com.somewater.display.HintedSprite;
	import com.somewater.display.Photo;
	import com.somewater.rabbit.application.windows.LevelSwitchWindow;
	import com.somewater.rabbit.storage.RewardDef;
	import com.somewater.rabbit.storage.LevelInstanceDef;
	import com.somewater.rabbit.storage.RewardInstanceDef;
	import com.somewater.storage.Lang;

	public class LevelRewardIcon extends HintedSprite implements IClear{

		public static const WIDTH = 100;
		public static const HEIGHT:int = 100;

		private var levelInstance:LevelInstanceDef;
		private var reward:RewardInstanceDef;
		private var photo:Photo;

		public function LevelRewardIcon(levelInstance:LevelInstanceDef, reward:RewardInstanceDef) {
			this.levelInstance = levelInstance;
			this.reward = reward;

			graphics.beginFill(0,0.1);
			graphics.drawRect(0,0,WIDTH,HEIGHT);

			var photoWidth:int = WIDTH * 0.95;
			var photoHeight:int = HEIGHT * 0.95;
			photo = new Photo(null, Photo.ORIENTED_CENTER, photoWidth, photoHeight, WIDTH * 0.5, HEIGHT * 0.5);
			addChild(photo);

			photo.source = LevelSwitchWindow.getImage(reward.rewardDef.slug);
			hint = Lang.t('REWARD_NAME_ID_' + reward.id);
		}

		public function clear():void
		{
			hint = null;
			levelInstance = null;
			photo.clear();
		}
	}
}
