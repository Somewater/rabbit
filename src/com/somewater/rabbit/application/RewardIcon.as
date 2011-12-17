package com.somewater.rabbit.application {
	import com.somewater.control.IClear;
	import com.somewater.display.HintedSprite;
	import com.somewater.display.Photo;
	import com.somewater.rabbit.application.windows.LevelSwitchWindow;
	import com.somewater.rabbit.social.PostingFactory;
	import com.somewater.rabbit.application.commands.PostingLevelSuccessCommand;
	import com.somewater.rabbit.storage.LevelInstanceDef;
	import com.somewater.rabbit.storage.RewardDef;
	import com.somewater.rabbit.storage.RewardInstanceDef;
	import com.somewater.storage.Lang;

	public class RewardIcon extends HintedSprite implements IClear{

		public static const WIDTH = 100;
		public static const HEIGHT:int = 100;

		private var reward:RewardDef;
		private var photo:Photo;

		public function RewardIcon(_reward:*) {
			this.reward = _reward is RewardDef ? _reward : (_reward is RewardInstanceDef ? RewardInstanceDef(_reward).rewardDef : null);

			graphics.beginFill(0,0);
			graphics.drawRect(0,0,WIDTH,HEIGHT);

			var photoWidth:int = WIDTH * 0.95;
			var photoHeight:int = HEIGHT * 0.95;
			photo = new Photo(null, Photo.ORIENTED_CENTER | Photo.SIZE_MIN, photoWidth, photoHeight, WIDTH * 0.5, HEIGHT * 0.5);
			addChild(photo);

			photo.source = PostingFactory.getImage(reward.slug);
			hint = reward.name;
		}

		public function clear():void
		{
			hint = null;
			reward = null;
			photo.clear();
		}
	}
}
