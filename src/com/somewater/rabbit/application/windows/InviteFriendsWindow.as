package com.somewater.rabbit.application.windows {
import com.somewater.rabbit.application.RewardManager;
import com.somewater.rabbit.application.commands.PostingFriendsInviteCommand;
	import com.somewater.rabbit.social.PostingFactory;
	import com.somewater.rabbit.storage.Config;
import com.somewater.rabbit.storage.RewardDef;
import com.somewater.rabbit.storage.UserProfile;
import com.somewater.storage.Lang;

	import flash.display.DisplayObject;

	import flash.display.Shape;
	import flash.display.Sprite;

	public class InviteFriendsWindow extends WindowWithImage{
	public function InviteFriendsWindow() {

		super(null, null, onButtonClick, [Lang.t('INVITE_WINDOW_BUTTON_INVITE'), Lang.t('INVITE_WINDOW_BUTTON_POSTING')]);

		setSize(WIDTH, HEIGHT);

		var friends_invited:int = UserProfile.instance.friendsInvited;
		var friends_need_invite:int = 1000;

		for each(var r:RewardDef in RewardManager.instance.getByType(RewardDef.TYPE_REFERER))
			if(r.degree > friends_invited && r.degree < friends_need_invite)
				friends_need_invite = r.degree;

		if(friends_need_invite == 1000)
			friends_need_invite = 1;// если человек пригласил более 10 друзей, просим пригоасить еще одного

		var image:DisplayObject = PostingFactory.getImage("rabbit.RabbitActor");
		image.scaleX = -1;
		image.x = image.width
		var imageHolder:Sprite = new Sprite();
		imageHolder.addChild(image)

		createTextAndImage(Lang.t('INVITE_WINDOW_TITLE'),
				Lang.t('INVITE_WINDOW_TEXT', {'friends_invited': friends_invited, 'friends_need_invite': friends_need_invite}), imageHolder);

		open();
	}
	private function onButtonClick(label:String):Boolean
	{
		if(label == Lang.t('INVITE_WINDOW_BUTTON_INVITE'))
		{
			onInviteClicked();
		}
		else if(label == Lang.t('INVITE_WINDOW_BUTTON_POSTING'))
		{
			onPostingClicked();
		}
		return true;
	}

	private function onInviteClicked():void {
		Config.loader.showInviteWindow();
	}

	private function onPostingClicked():void {
		new MessagePostClose(1, PostingFriendsInviteCommand, function(data:*):void{
			// юзер запостил приглашение в игру
		});
	}
}
}
