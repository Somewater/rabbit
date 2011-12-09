package com.somewater.rabbit.social {
	import com.somewater.rabbit.application.AppServerHandler;
	import com.somewater.rabbit.application.ServerLogic;
	import com.somewater.rabbit.storage.Config;
	import com.somewater.rabbit.storage.LevelInstanceDef;
	import com.somewater.rabbit.storage.Lib;
	import com.somewater.rabbit.storage.RewardDef;
	import com.somewater.rabbit.storage.UserProfile;
	import com.somewater.storage.Lang;

	import flash.display.DisplayObject;
	import flash.display.MovieClip;

	import flash.utils.Dictionary;

	public class PostingLevelSuccessCommand implements ICommand{

		private var data:Dictionary;
		private var levelInstance:LevelInstanceDef;

		public function PostingLevelSuccessCommand(levelInstance:LevelInstanceDef, onComplete:Function, onError:Function)
		{
			this.data = new Dictionary(true);
			this.levelInstance = levelInstance;
			data['onComplete'] = onComplete;
			data['onError'] = onError;
		}

		public function execute():void
		{
			if(Config.loader.canPost())
			{
				var image:MovieClip = Lib.createMC('posting.PostingLevelSuccess');
				image.text_field.text = levelInstance.number.toString();
				var imageUrl:String = Config.loader.getFilePath('PostingLevelSuccess');
				var postdata:String = Config.loader.serverHandler.toJson({'poster':UserProfile.instance.socialUser.id, 'level':levelInstance.number});
				Config.loader.posting(UserProfile.instance.socialUser,
						Lang.t('POSTING_LEVEL_PASSES_TITLE'),
						Lang.t('POSTING_LEVEL_PASSES_TEXT', {'level_number':levelInstance.number}), image, imageUrl, postdata,
								function(...args):void{
									// on complete
									UserProfile.instance.postings += 1;
									ServerLogic.checkAddReward(UserProfile.instance, null, null, RewardDef.TYPE_POSTING, UserProfile.instance.postings)
									AppServerHandler.instance.onPosting(UserProfile.instance, levelInstance);
									if(data['onComplete'])
										data['onComplete']();
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
