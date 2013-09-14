package com.somewater.rabbit.application.windows {
	import com.somewater.display.Window;
	import com.somewater.rabbit.Stat;
	import com.somewater.rabbit.application.AppServerHandler;
	import com.somewater.rabbit.application.OrangeButton;
	import com.somewater.rabbit.application.UsersSelector;
	import com.somewater.rabbit.application.commands.PostingFriendsInviteCommand;
	import com.somewater.rabbit.storage.Config;
	import com.somewater.rabbit.storage.GameUser;
	import com.somewater.rabbit.storage.Lib;
	import com.somewater.rabbit.storage.UserProfile;
	import com.somewater.social.SocialUser;
	import com.somewater.storage.Lang;
	import com.somewater.text.EmbededTextField;
	import com.somewater.text.TextInputPrompted;

	import flash.display.DisplayObject;

	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.text.TextFieldAutoSize;

	public class NeighboursWindow extends Window{

		private var usersSelector:UsersSelector;
		private var submitButton:OrangeButton;
		private var input:TextInputPrompted;

		private var postingQueue:Array = [];
		private static var antiGC:Array = []

		public function NeighboursWindow(selectedUser:SocialUser = null) {
			var notNeighbours:Array = [];
			var neighboursIds:Object = {};
			for each(var g:GameUser in UserProfile.instance.neighbours)
				neighboursIds[g.uid] = true;
			for each(var f:SocialUser in Config.loader.getFriends())
				if(!neighboursIds[f.id])
					notNeighbours.push(f);

			super(null, Lang.t('NEIGHBOURS_WND_TITLE'), null, []);

			setSize(600, 550);

			var conntentWidth:int = 530;
			var startX:int = (this.width - conntentWidth) * 0.5;
			var stopX:int = startX + conntentWidth;

			var image:DisplayObject = Lib.createMC('interface.NeighbourWndImage');
			image.x = stopX - image.width;
			image.y = 70;
			addChild(image);
			var textTF:EmbededTextField = new EmbededTextField(Config.FONT_SECONDARY, 0x373535, 12, false, true);
			textTF.text = "Добавляя друзей к себе в соседи,  ты сможешь собирать круглики на их полянках -\nэто поможет тебе пройти игру быстрее!";
			textTF.width = this.width * 0.9;
			textTF.x = startX;
			textTF.y = 50;
			addChild(textTF);
			var inputTextBack:DisplayObject = Lib.createMC('interface.InputTextBack');
			inputTextBack.x = startX;
			inputTextBack.y = textTF.y + textTF.textHeight + 20;
			addChild(inputTextBack);
			input = new TextInputPrompted(Config.FONT_SECONDARY, 0);
			input.addEventListener(Event.CHANGE, onInputText);
			input.promptColor = 0xE51721;
			input.x = inputTextBack.x + 7;
			input.y = inputTextBack.y + 6.5;
			input.autoSize = TextFieldAutoSize.NONE;
			input.multiline = false;
			input.width = 180;
			input.prompt = 'введи имя друга'
			addChild(input);
			input.text = '';

			usersSelector = new UsersSelector(notNeighbours);
			usersSelector.setSize(conntentWidth, 300);
			if(selectedUser)
				usersSelector.selected = [selectedUser];
			addChild(usersSelector);
			usersSelector.x = startX;
			usersSelector.y = 160;
			//usersSelector.scrollToSelected();
			usersSelector.addEventListener(Event.CHANGE, onSelectedChanged);
			usersSelector.addEventListener(UsersSelector.FRIEND_WITH_REQUEST_CLICKED, onFriendWithRequest);

			submitButton = new OrangeButton();
			submitButton.label = Lang.t('NEIGHBOURS_SUBMIT_BTN');
			submitButton.setSize(200, 32);
			submitButton.x = (width - submitButton.width) * 0.5;
			submitButton.y = usersSelector.y + usersSelector.height + 30;
			addChild(submitButton);
			submitButton.addEventListener(MouseEvent.CLICK, onSubmit);
			onSelectedChanged();

			open();

			Config.stat(Stat.WND_NEIGHBOURS);
		}

		override public function clear():void {
			super.clear();
			usersSelector.clear();
			usersSelector.removeEventListener(Event.CHANGE, onSelectedChanged);
			usersSelector.removeEventListener(UsersSelector.FRIEND_WITH_REQUEST_CLICKED, onFriendWithRequest);
			submitButton.clear();
			submitButton.removeEventListener(MouseEvent.CLICK, onSubmit);
			input.removeEventListener(Event.CHANGE, onInputText);
		}

		private function onSelectedChanged(event:Event = null):void {
			submitButton.enabled = usersSelector.selected.length > 0;
		}

		private function onInputText(event:Event):void {
			if(input.text.length == 0){
				usersSelector.filter(null);
			} else {
				var texts:Array = input.text.toLowerCase().split(/\s+/);
				usersSelector.filter(function(s:SocialUser):Boolean{
					for each(var text:String in texts)
						if(s.firstName.toLowerCase().indexOf(text) != -1 || s.lastName.toLowerCase().indexOf(text) != -1)
							return true;
					return false;
				})
			}
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

		private function onFriendWithRequest(event:Event):void {
			AppServerHandler.instance.sendNeighboursAccepts([usersSelector.lastClickedFriendWithRequest]);
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
