package com.somewater.rabbit.application.windows {
	import com.somewater.display.Window;
	import com.somewater.rabbit.application.AppServerHandler;
	import com.somewater.rabbit.application.OrangeButton;
	import com.somewater.rabbit.application.UsersSelector;
	import com.somewater.rabbit.application.commands.PostingFriendsInviteCommand;
	import com.somewater.rabbit.storage.Config;
	import com.somewater.rabbit.storage.UserProfile;
	import com.somewater.social.SocialUser;
	import com.somewater.storage.Lang;

	import flash.events.Event;
	import flash.events.MouseEvent;

	public class NeighboursWindow extends Window{

		private var usersSelector:UsersSelector;
		private var submitButton:OrangeButton;

		private var postingQueue:Array = [];
		private static var antiGC:Array = []

		public function NeighboursWindow(users:Array, selectedUser:SocialUser = null) {
			super(null, Lang.t('NEIGHBOURS_WND_TITLE'), null, []);

			setSize(600, 550);
			usersSelector = new UsersSelector(users);
			usersSelector.setSize(530, 400);
			if(selectedUser)
				usersSelector.selected = [selectedUser];
			addChild(usersSelector);
			usersSelector.x = (this.width - 530) * 0.5;
			usersSelector.y = 50;
			usersSelector.scrollToSelected();
			usersSelector.addEventListener(Event.CHANGE, onSelectedChanged);

			submitButton = new OrangeButton();
			submitButton.label = Lang.t('NEIGHBOURS_SUBMIT_BTN');
			submitButton.setSize(200, 32);
			submitButton.x = (width - submitButton.width) * 0.5;
			submitButton.y = usersSelector.y + usersSelector.height + 30;
			addChild(submitButton);
			submitButton.addEventListener(MouseEvent.CLICK, onSubmit);
			onSelectedChanged();

			open();
		}

		override public function clear():void {
			super.clear();
			usersSelector.clear();
			usersSelector.removeEventListener(Event.CHANGE, onSelectedChanged);
			submitButton.clear();
			submitButton.removeEventListener(MouseEvent.CLICK, onSubmit);
		}

		private function onSelectedChanged(event:Event = null):void {
			submitButton.enabled = usersSelector.selected.length > 0;
		}

		private function onSubmit(event:Event):void {
			var selectedSocualUsers:Array = usersSelector.selected;
			if(selectedSocualUsers.length) {
				close();
				var selectedAppFriends:Array = [];
				var selectedFriends:Array = [];
				var s:SocialUser;
				for each(s in  selectedSocualUsers){
					if(s.isAppFriend)
						selectedAppFriends.push(s);

					if(!s.isAppFriend || Config.memory['disableFriendBarInviteBox'])
						selectedFriends.push(s);
				}

				if(selectedAppFriends.length)
					AppServerHandler.instance.sendNeighboursAccepts(selectedAppFriends);

				if(selectedFriends.length) {
					var canSendSelectedFriends:Array = []
					for each(s in selectedFriends)
						if(Config.loader.canPost(s.id))
							canSendSelectedFriends.push(s);
					if(canSendSelectedFriends.length > 30 || canSendSelectedFriends.length == 0){
						Config.loader.showInviteWindow();
					} else {
						postingQueue = canSendSelectedFriends;
						antiGC.push(this)
						sendNextPosting();
					}
				}
			}
		}

		private function sendNextPosting(...args):void {
			var s:SocialUser = postingQueue.pop();
			if(s){
				new PostingFriendsInviteCommand(s, sendNextPosting, sendNextPosting).execute();
			} else {
				antiGC.splice(antiGC.indexOf(this), 1);
			}
		}
	}
}
