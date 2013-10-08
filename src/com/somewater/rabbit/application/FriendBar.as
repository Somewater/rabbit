package com.somewater.rabbit.application
{
	import com.greensock.TweenLite;
	import com.greensock.TweenMax;
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
		public var MIN_WIDTH:int = HEIGHT;

		private static var lastCommonPosition:int = 0;
		
		private var ground:DisplayObject;

		private var contentHolder:Sprite;
		private var leftArrow:SimpleButton;
		private var leftStuporArrow:SimpleButton;
		private var rightArrow:SimpleButton;
		private var rightStuporArrow:SimpleButton;
		private var requestCounter:NumberIndicator;
		private var rollUnrollBtn:SimpleButton;
		
		private var friendIcons:Array = [];
		private var neighbours:Array;
		private var neighboursUids:Object;
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

			contentHolder = new Sprite();
			addChild(contentHolder);
			
			leftArrow = Lib.createMC("interface.ArrowButton");
			leftArrow.addEventListener(MouseEvent.CLICK, onArrowClick);
			leftArrow.x = 14;
			leftArrow.y = 25;
			contentHolder.addChild(leftArrow);

			rollUnrollBtn = Lib.createMC("interface.ArrowButtonHeight");
			rollUnrollBtn.addEventListener(MouseEvent.CLICK, onUnrollClick);
			rollUnrollBtn.y = 25;
			contentHolder.addChild(rollUnrollBtn);
			
			leftStuporArrow = Lib.createMC("interface.ArrowStuporButton");
			leftStuporArrow.addEventListener(MouseEvent.CLICK, onArrowClick);
			leftStuporArrow.x = 14;
			leftStuporArrow.y = 72;
			contentHolder.addChild(leftStuporArrow);
			
			rightArrow = Lib.createMC("interface.ArrowButton");
			rightArrow.addEventListener(MouseEvent.CLICK, onArrowClick);
			rightArrow.scaleX = -1;
			rightArrow.y = 25;
			contentHolder.addChild(rightArrow);
			
			rightStuporArrow = Lib.createMC("interface.ArrowStuporButton");
			rightStuporArrow.addEventListener(MouseEvent.CLICK, onArrowClick);
			rightStuporArrow.scaleX = -1;
			rightStuporArrow.y = 72;
			contentHolder.addChild(rightStuporArrow);

			fullAppFriends();

			notAppFriends = [];
			var appFriendsUids:Object = {};
			var g:GameUser;
			for each(g in neighbours)
				appFriendsUids[g.uid] = true;
			for each(var s:SocialUser in Config.loader.getFriends())
				if(!appFriendsUids[s.id])
					notAppFriends.push(s);

			ITEMS = neighbours.length > 3 ? Math.max(6, -1 + int((Config.WIDTH - 70 - 160) / 80)) : 4;
			
			for(var i:int = 0;i<=ITEMS;i++)
			{
				var friendIcon:FriendIcon = new FriendIcon(this);
				friendIcon.x = 55 + i * 80;     
				friendIcon.y = 27;
				contentHolder.addChild(friendIcon);
				friendIcons.push(friendIcon);
			}
			position = lastCommonPosition;

			requestCounter = new NumberIndicator();
			requestCounter.visible = false;
			contentHolder.addChild(requestCounter);
			updateNeighbourRequestIcon();

			if(notAppFriends.length || realNeighbours.length) {
				notAppFriends.sort(function(a:SocialUser, b:SocialUser):int{ return Math.random() > 0.5 ? 1 : -1 });
				refreshAddNeighbourTimer = new Timer(10000);
				refreshAddNeighbourTimer.addEventListener(TimerEvent.TIMER, refreshAddNeighbourIcon);
				refreshAddNeighbourTimer.start();
				refreshAddNeighbourIcon();
			}

			WIDTH = ground.width = 160 + (ITEMS + 1) * 80;
			HEIGHT = ground.height = HEIGHT;
			rightStuporArrow.x = rightArrow.x = WIDTH - 24- 50;
			rollUnrollBtn.x = WIDTH - 24 - 20;

			UserProfile.instance.addEventListener(NeighbourAddedEvent.NEIGHBOUR_ADDED_EVENT, onNeighbourAdded);
			addEventListener(MouseEvent.CLICK, onRollUnrollClick);
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
			rollUnrollBtn.removeEventListener(MouseEvent.CLICK, onUnrollClick);

			if(refreshAddNeighbourTimer){
				refreshAddNeighbourTimer.removeEventListener(TimerEvent.TIMER, refreshAddNeighbourIcon);
				refreshAddNeighbourTimer.stop();
				refreshAddNeighbourTimer = null;
			}

			UserProfile.instance.removeEventListener(NeighbourAddedEvent.NEIGHBOUR_ADDED_EVENT, onNeighbourAdded);
			removeEventListener(MouseEvent.CLICK, onRollUnrollClick);
			clearRollUnrollAnim();
		}

		private function onNeighbourAdded(event:NeighbourAddedEvent):void {
			fullAppFriends();

			for(var i:int = 0;i<notAppFriends.length;i++)
				if((notAppFriends[i] as SocialUser).id == event.uid){
					notAppFriends.splice(i, 1);
					break;
				}

			var pos:int = position;
			_position = -1;
			position = pos;

			updateNeighbourRequestIcon();
		}

		private function fullAppFriends():void{
			neighboursUids = {};
			neighbours = UserProfile.instance.neighbours;
			//neighbours.push(ImaginaryGameUser.instance)
			neighbours.push(UserProfile.instance)
			neighbours.sortOn("levelNumber", Array.NUMERIC | Array.DESCENDING);
			for each(var n:GameUser in neighbours)
				neighboursUids[n.uid] = true;
		}

		private function get friendItemsLength():int {
			return ITEMS - (notAppFriends.length ? 1 : 0);
		}
		
		public function set position(value:int):void
		{
			value = Math.max(0, Math.min(neighbours.length - friendItemsLength, value));
			if(value != _position)
			{
				lastCommonPosition = _position = value;
				for(var i:int = 0;i<friendItemsLength;i++)
				{
					var friendIcon:FriendIcon = friendIcons[i];
					friendIcon.setUser(neighbours[i + _position]);
				}
				
				var friendsMore:Boolean = neighbours.length > friendItemsLength;
				setButtonEnable(leftArrow, friendsMore  && _position > 0);
				setButtonEnable(leftStuporArrow, friendsMore && _position > 0);
				setButtonEnable(rightArrow, friendsMore && _position < neighbours.length - friendItemsLength);
				setButtonEnable(rightStuporArrow, friendsMore && _position < neighbours.length - friendItemsLength);
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
			this.position = neighbours.indexOf(ImaginaryGameUser.instance);

			for each(var icon:FriendIcon in friendIcons)
				if(icon.imaginaryFriendIcon)
					return icon.highlightTarget;
			return null;
		}

		private function refreshAddNeighbourIcon(event:Event = null):void {
			var user:SocialUser;
			if(notAppFriends.length){
				user = notAppFriends[notAppFriendsPos++ % notAppFriends.length];
			} else {
				var rNeighbours:Array = this.realNeighbours;
				user = (rNeighbours[notAppFriendsPos++ % rNeighbours.length] as GameUser).socialUser;
			}

			var icon:FriendIcon = friendTimerIcon();
			if(icon.parent != this)
				addChild(icon);
			icon.setUser(user);
			requestCounter.x = icon.x + 55;
			requestCounter.y = icon.y - 5;
		}

		private function friendTimerIcon():FriendIcon{
			return friendIcons[friendIcons.length - 1] as FriendIcon;
		}

		private function updateNeighbourRequestIcon():void {
			var requestNum:int = 0;
			var requestUids:Object = UserProfile.instance.neighbourRequestUids;
			for each(var f:SocialUser in Config.loader.getFriends()){
				if(!neighboursUids[f.id] && requestUids[f.id]){
					requestNum++;
				}
			}
			requestCounter.visible = requestNum > 0;
			requestCounter.number = requestNum;
		}

		public function rollUp():void {
			if(!closed) return;
			closed = false;
			TweenLite.to(ground, 0.3, {width: WIDTH, height: HEIGHT, onComplete: function(){
				setFriendTimerIconPos();
				contentHolder.visible = true;
				TweenMax.to(contentHolder, 0.3, {alpha: 1, onComplete: clearRollUnrollAnim});
			}});
			buttonMode = useHandCursor = false;
		}

		private var closed:Boolean = false;
		public function rollDown(force:Boolean = false):void {
			if(closed) return;
			closed = true;
			if(force){
				contentHolder.alpha = 0;
				contentHolder.visible = false;
				ground.width = ground.height = HEIGHT;
				this.visible = notAppFriends.length > 0 ||realNeighbours.length > 0;
				setFriendTimerIconPos(force);
			} else {
				setFriendTimerIconPos();
				TweenMax.to(contentHolder, 0.3, {alpha: 0, onComplete: function():void{
					contentHolder.visible = false;
					TweenMax.to(ground, 0.3, {width: MIN_WIDTH, height: HEIGHT, onComplete: clearRollUnrollAnim});
				}})
			}
			buttonMode = useHandCursor = true;
		}

		private function clearRollUnrollAnim():void {
			TweenLite.killTweensOf(ground, true);
			TweenLite.killTweensOf(contentHolder, true);
			TweenLite.killTweensOf(friendIcons, true);
		}

		private function setFriendTimerIconPos(force:Boolean = false):void{
			var friendIcon:FriendIcon = friendTimerIcon();
			if(closed){
				if(force){
					friendIcon.x = (MIN_WIDTH - friendIcon.width) * 0.5 + 2;
					friendIcon.y = 23;
				} else {
					TweenMax.to(friendIcon, 0.15, {
						x: (MIN_WIDTH - friendIcon.width) * 0.5 + 2,
						y: 23
					})
				}
			} else {
				TweenMax.to(friendIcon, 0.15, {
					x: 55 + friendIcons.indexOf(friendIcon) * 80,
					y: 27
				})
			}
		}

		public function get realNeighbours():Array {
			return  neighbours.filter(function(u:GameUser, ...args):Boolean{
				return  !u.itsMe() && !(u is ImaginaryGameUser);
			})
		}

		private function onRollUnrollClick(event:Event):void {
			if(closed){
				rollUp();
				event.stopImmediatePropagation()
			}
		}

		private function onUnrollClick(event:Event):void {
			rollDown();
			event.stopImmediatePropagation();
		}

		public function canIconActions():Boolean {
			return !closed;
		}
	}
}