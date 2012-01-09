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

	public class PostingFriendsInviteCommand implements ICommand{

		private var data:Dictionary;

		public function PostingFriendsInviteCommand(onComplete:Function, onError:Function)
		{
			this.data = new Dictionary(true);
			data['onComplete'] = onComplete;
			data['onError'] = onError;
		}

		public function execute():void
		{
			if(Config.loader.canPost())
			{
				var image:DisplayObject = PostingFactory.createFriendsInvitePosting();
				var imageUrl:String = Config.loader.getFilePath('friends_invite_posting' + levelInstance.number.toString());
				var postdata:String = Config.loader.serverHandler.toJson({'type':'level_pass_posting','poster':UserProfile.instance.socialUser.id, 'level':levelInstance.number});
				Config.loader.posting(UserProfile.instance.socialUser,
						Lang.t('POSTING_LEVEL_PASSES_TITLE'),
						Lang.t('POSTING_LEVEL_PASSES_TEXT', {'level_number':levelInstance.number}), image, imageUrl, postdata,
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
