package com.somewater.rabbit.application.commands {
	import com.somewater.rabbit.social.*;
	import com.somewater.rabbit.application.AppServerHandler;
	import com.somewater.rabbit.application.ServerLogic;
	import com.somewater.rabbit.storage.Config;
	import com.somewater.rabbit.storage.LevelInstanceDef;
	import com.somewater.rabbit.storage.Lib;
	import com.somewater.rabbit.storage.RewardDef;
	import com.somewater.rabbit.storage.RewardInstanceDef;
	import com.somewater.rabbit.storage.UserProfile;
	import com.somewater.storage.Lang;

	import flash.display.DisplayObject;
	import flash.display.MovieClip;

	import flash.utils.Dictionary;

	public class PostingRewardCommand implements ICommand{

		private var data:Dictionary;
		private var reward:RewardDef;

		public function PostingRewardCommand(reward:RewardDef, onComplete:Function, onError:Function)
		{
			this.data = new Dictionary(true);
			this.reward = reward;
			data['onComplete'] = onComplete;
			data['onError'] = onError;
		}

		public function execute():void
		{
			if(Config.loader.canPost())
			{
				var image:DisplayObject = PostingFactory.createRewardPosting(reward);
				var imageUrl:String = Config.loader.getFilePath('reward_posting_' + reward.id);
				var postdata:String = Config.loader.serverHandler.toJson({'type':'reward_posting','poster':UserProfile.instance.socialUser.id, 'reward':reward.id});
				Config.loader.posting(UserProfile.instance.socialUser,
						Lang.t('POSTING_REWARD_PASSES_TITLE'),
						Lang.t('POSTING_REWARD_PASSES_TEXT', {'reward_name':reward.name}), image, imageUrl, postdata,
								function(...args):void{
									// on complete
									UserProfile.instance.postings += 1;
									var reward:RewardInstanceDef = ServerLogic.checkAddReward(UserProfile.instance, null, null, RewardDef.TYPE_POSTING, UserProfile.instance.postings)
									AppServerHandler.instance.onPosting(UserProfile.instance);
									if(data['onComplete'])
										data['onComplete'](reward);
								}, function(...args):void{
									// on error
									if(data['onError'])
										data['onError']();
								});
			}
			else
				throw new Error('Posting not implemented in current environment');
		}
	}
}
