package com.somewater.rabbit.application
{
	import com.somewater.control.IClear;
	import com.somewater.rabbit.events.NeighbourAddedEvent;
	import com.somewater.rabbit.storage.Config;
	import com.somewater.rabbit.storage.GameUser;
	import com.somewater.rabbit.storage.Lib;
	import com.somewater.rabbit.storage.UserProfile;
	import com.somewater.social.SocialUser;

	import flash.display.DisplayObject;
	import flash.display.SimpleButton;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.events.TimerEvent;
	import flash.utils.Timer;

	public class FriendBar extends Sprite implements IClear
	{
		public var WIDTH:int = 510;
		public var HEIGHT:int = 120;

		private static var lastCommonPosition:int = 0;
		
		private var ground:DisplayObject;
		private var leftArrow:SimpleButton;
		private var leftStuporArrow:SimpleButton;
		private var rightArrow:SimpleButton;
		private var rightStuporArrow:SimpleButton;
		
		private var friendIcons:Array = [];
		private var friends:Array;
		private var notAppFriends:Array;
		private var notAppFriendsPos:int = 0;
		private var _position:int = -1;

		private var refreshAddNeighbourTimer:Timer;

		private var ITEMS:int = 4;
		
		public function FriendBar()
		{
			super();
			
			ground = Lib.createMC("interface.LightGreenGround");
			addChild(ground);
			
			leftArrow = Lib.createMC("interface.ArrowButton");
			leftArrow.addEventListener(MouseEvent.CLICK, onArrowClick);
			leftArrow.x = 14;
			leftArrow.y = 25;
			addChild(leftArrow);
			
			leftStuporArrow = Lib.createMC("interface.ArrowStuporButton");
			leftStuporArrow.addEventListener(MouseEvent.CLICK, onArrowClick);
			leftStuporArrow.x = 14;
			leftStuporArrow.y = 72;
			addChild(leftStuporArrow);
			
			rightArrow = Lib.createMC("interface.ArrowButton");
			rightArrow.addEventListener(MouseEvent.CLICK, onArrowClick);
			rightArrow.scaleX = -1;
			rightArrow.y = 25;
			addChild(rightArrow);
			
			rightStuporArrow = Lib.createMC("interface.ArrowStuporButton");
			rightStuporArrow.addEventListener(MouseEvent.CLICK, onArrowClick);
			rightStuporArrow.scaleX = -1;
			rightStuporArrow.y = 72;
			addChild(rightStuporArrow);

			fullAppFriends();

			notAppFriends = [];
			var appFriendsUids:Object = {};
			var g:GameUser;
			for each(g in friends)
				appFriendsUids[g.uid] = true;
			for each(var s:SocialUser in Config.loader.getFriends())
				if(!appFriendsUids[s.id])
					notAppFriends.push(s);

			ITEMS = friends.length > 3 ? Math.max(6, -1 + int((Config.WIDTH - 70 - 110) / 80)) : 4;
			
			for(var i:int = 0;i<=ITEMS;i++)
			{
				var friendIcon:FriendIcon = new FriendIcon();
				friendIcon.x = 55 + i * 80;     
				friendIcon.y = 27;
				addChild(friendIcon);
				friendIcons.push(friendIcon);
			}
			position = lastCommonPosition;

			if(notAppFriends.length) {
				notAppFriends.sort(function(a:SocialUser, b:SocialUser):int{ return Math.random() > 0.5 ? 1 : -1 });
				refreshAddNeighbourTimer = new Timer(10000);
				refreshAddNeighbourTimer.addEventListener(TimerEvent.TIMER, refreshAddNeighbourIcon);
				refreshAddNeighbourTimer.start();
				refreshAddNeighbourIcon();
			}

			WIDTH = ground.width = 110 + (ITEMS + 1) * 80;
			HEIGHT = ground.height = HEIGHT;
			rightStuporArrow.x = rightArrow.x = WIDTH - 24;

			UserProfile.instance.addEventListener(NeighbourAddedEvent.NEIGHBOUR_ADDED_EVENT, onNeighbourAdded);
		}
		
		public function clear():void
		{
			var i:int;
			for(i = 0;i<friendIcons.length;i++)
				IClear(friendIcons[i]).clear();
			
			leftArrow.removeEventListener(MouseEvent.CLICK, onArrowClick);
			leftStuporArrow.removeEventListener(MouseEvent.CLICK, onArrowClick);
			rightStuporArrow.removeEventListener(MouseEvent.CLICK, onArrowClick);
			rightArrow.removeEventListener(MouseEvent.CLICK, onArrowClick);

			if(refreshAddNeighbourTimer){
				refreshAddNeighbourTimer.removeEventListener(TimerEvent.TIMER, refreshAddNeighbourIcon);
				refreshAddNeighbourTimer.stop();
				refreshAddNeighbourTimer = null;
			}

			UserProfile.instance.removeEventListener(NeighbourAddedEvent.NEIGHBOUR_ADDED_EVENT, onNeighbourAdded);
		}

		private function onNeighbourAdded(event:NeighbourAddedEvent):void {
			fullAppFriends();

			for(var i:int = 0;i<notAppFriends.length;i++)
				if((notAppFriends[i] as SocialUser).id == event.uid){
					notAppFriends.splice(i, 1);
					break;
				}
		}

		private function fullAppFriends():void{
			friends = UserProfile.instance.neighbours;
			friends.push(ImaginaryGameUser.instance)
			friends.sortOn("levelNumber", Array.NUMERIC | Array.DESCENDING);
		}

		private function get friendItemsLength():int {
			return ITEMS - (notAppFriends.length ? 1 : 0);
		}
		
		public function set position(value:int):void
		{
			value = Math.max(0, Math.min(friends.length - friendItemsLength, value));
			if(value != _position)
			{
				lastCommonPosition = _position = value;
				for(var i:int = 0;i<friendItemsLength;i++)
				{
					var friendIcon:FriendIcon = friendIcons[i];
					friendIcon.setUser(friends[i + _position]);
				}
				
				var friendsMore:Boolean = friends.length > friendItemsLength;
				setButtonEnable(leftArrow, friendsMore  && _position > 0);
				setButtonEnable(leftStuporArrow, friendsMore && _position > 0);
				setButtonEnable(rightArrow, friendsMore && _position < friends.length - friendItemsLength);
				setButtonEnable(rightStuporArrow, friendsMore && _position < friends.length - friendItemsLength);
			}
		}
		public function get position():int {return _position;} 
		
		private function setButtonEnable(button:SimpleButton, enabled:Boolean):void
		{
			button.enabled = enabled;
			button.alpha = enabled?1:0.6;
		}
		
		private function onArrowClick(e:Event):void
		{
			var value:int;
			var arrow:SimpleButton = e.currentTarget as SimpleButton;
			if(!arrow.enabled) return;
			if(arrow == leftArrow)
				value = -friendItemsLength;
			else if(arrow == leftStuporArrow)
				value = -100000;
			if(arrow == rightArrow)
				value = friendItemsLength;
			else if(arrow == rightStuporArrow)
				value = 100000;
			
			position += value;
		}

		// для тьюториала
		public function getImaginaryFriendIcon():DisplayObject
		{
			// перемотать так, чтобы была видна иконка воображаемого друга
			this.position = friends.indexOf(ImaginaryGameUser.instance);

			for each(var icon:FriendIcon in friendIcons)
				if(icon.imaginaryFriendIcon)
					return icon.highlightTarget;
			return null;
		}

		private function refreshAddNeighbourIcon(event:Event = null):void {
			var user:SocialUser = notAppFriends[notAppFriendsPos++ % notAppFriends.length];
			FriendIcon(friendIcons[friendIcons.length - 1]).setUser(user);
		}
	}
}