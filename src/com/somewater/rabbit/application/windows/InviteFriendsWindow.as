package com.somewater.rabbit.application.windows {
import com.somewater.display.Window;
import com.somewater.rabbit.application.RewardManager;
import com.somewater.rabbit.storage.Config;
import com.somewater.rabbit.storage.RewardDef;
import com.somewater.rabbit.storage.UserProfile;
import com.somewater.storage.Lang;

public class InviteFriendsWindow extends Window{
	public function InviteFriendsWindow() {
		var friends_invited:int = UserProfile.instance.friendsInvited;
		var friends_need_invite:int = 1000;

		for each(var r:RewardDef in RewardManager.instance.getByType(RewardDef.TYPE_REFERER))
			if(r.degree > friends_invited && r.degree < friends_need_invite)
				friends_need_invite = r.degree;

		if(friends_need_invite == 1000)
			friends_need_invite = 1;// если человек пригласил более 10 друзей, просим пригоасить еще одного

		super(Lang.t('INVITE_WINDOW_TEXT', {'friends_invited': friends_invited, 'friends_need_invite': friends_need_invite})
				, null, onButtonClick, [Lang.t('INVITE_WINDOW_BUTTON_INVITE'), Lang.t('INVITE_WINDOW_BUTTON_POSTING')])
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
		new PostingFriendsInviteCommand().execute();
	}
}
}
