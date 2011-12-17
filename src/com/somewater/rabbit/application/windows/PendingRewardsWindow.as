package com.somewater.rabbit.application.windows {
	import com.somewater.display.Photo;
	import com.somewater.display.Window;
	import com.somewater.rabbit.application.HideOrangeButton;
	import com.somewater.rabbit.application.OrangeButton;
	import com.somewater.rabbit.application.RewardPanel;
	import com.somewater.rabbit.application.commands.PostingRewardCommand;
	import com.somewater.rabbit.storage.Config;
	import com.somewater.rabbit.storage.LevelDef;
	import com.somewater.rabbit.storage.LevelInstanceDef;
	import com.somewater.rabbit.storage.Lib;
	import com.somewater.rabbit.storage.RewardDef;
	import com.somewater.rabbit.storage.RewardInstanceDef;
	import com.somewater.storage.Lang;
	import com.somewater.text.EmbededTextField;
	import com.somewater.utils.MovieClipHelper;

	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.display.Shape;
	import flash.display.Sprite;

	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Rectangle;
	import flash.text.TextField;

	public class PendingRewardsWindow extends Window{

		protected const WIDTH:int = 600;
		protected const HEIGHT:int = 400;

		protected var rewards:Array;

		protected var starIcon:DisplayObjectContainer;
		protected var okButton:OrangeButton;
		protected var postingButton:OrangeButton;
		private var rewardPanel:RewardPanel;

		public function PendingRewardsWindow(rewards:Array) {
			this.rewards = rewards;
			super(null, null, null, []);

			setSize(WIDTH, HEIGHT);

			createContent();

			createButtons();

			individual = true;
			open();
		}

		protected function createButtons():void
		{
			okButton = Config.loader.canPost() ? new HideOrangeButton() : new OrangeButton();
			okButton.label = Lang.t("OK");
			if(okButton.width < 125)
				okButton.width = 125;
			okButton.x = (width - okButton.width) * 0.5;
			okButton.y = height - okButton.height - 40;
			addChild(okButton);
			okButton.addEventListener(MouseEvent.CLICK, onOkClicked);

			if(Config.loader.canPost())
			{
				postingButton = new OrangeButton();
				postingButton.label = Lang.t("POSTING_LEVEL_BUTTON");
				postingButton.width = Math.max(postingButton.width, okButton.width);
				postingButton.y = okButton.y;
				addChild(postingButton);
				postingButton.addEventListener(MouseEvent.CLICK, onPostingClicked);

				var space:Number = (width -100 - okButton.width - postingButton.width) / 3;
				okButton.x = 50 + space;
				postingButton.x = 50 + space * 2 + okButton.width;
			}
		}


		override public function defaultButtonPress():void {
			onOkClicked(null);
		}

		private function onPostingClicked(e:MouseEvent):void
		{
			new MessagePostClose(rewards[0], PostingRewardCommand, function(data:RewardDef):void{
				// nothing
			})
			close();
		}

		private function onOkClicked(event:MouseEvent):void {
			close();
		}

		protected function createContent():void {
			var succGround:DisplayObject = Lib.createMC('interface.LevelSuccessWindow_starGround');
			succGround.x = -3;
			succGround.y = -12;

			var succGroundMask:Shape = new Shape();
			succGround.mask = succGroundMask;
			succGroundMask.graphics.beginFill(0);
			succGroundMask.graphics.drawRoundRectComplex(0,0,width,height,10,10,10,10);
			addChild(succGroundMask);
			addChild(succGround);

			var onlyOneReward:RewardDef = (rewards.length == 1 ? (rewards[0] is RewardDef ? rewards[0] : RewardInstanceDef(rewards[0]).rewardDef) : null);
			var refererReward:Boolean = onlyOneReward != null && onlyOneReward.type == RewardDef.TYPE_REFERER;
			var familiarReward:Boolean = onlyOneReward != null && onlyOneReward.type == RewardDef.TYPE_FAMILIAR;
			var text:String = familiarReward ? 'PENDING_REWARDS_WINDOW_TEXT_ONLY_FAMILIAR' : (refererReward ? 'PENDING_REWARDS_WINDOW_TEXT_ONLY_REFERER'
									: (onlyOneReward != null ? 'PENDING_REWARDS_WINDOW_TEXT_SINGLE' : 'PENDING_REWARDS_WINDOW_TEXT_MANY'));


			var bonusesTitle:EmbededTextField = new EmbededTextField(null, 0xDB661B,20,false, true);
			bonusesTitle.width = this.width - 150;
			bonusesTitle.text = Lang.t(text);
			bonusesTitle.x = (this.width - bonusesTitle.width) * 0.5;
			bonusesTitle.y = 50;
			addChild(bonusesTitle);

			rewardPanel = new RewardPanel(rewards);
			rewardPanel.y = 170;
			rewardPanel.x = (this.width - rewardPanel.width) * 0.5;
			addChild(rewardPanel);
		}


		override public function clear():void {
			rewards = null;
			okButton.removeEventListener(MouseEvent.CLICK, onOkClicked)
			if(postingButton)
				postingButton.removeEventListener(MouseEvent.CLICK, onPostingClicked);
			rewardPanel.clear();
			super.clear();
		}
	}
}
