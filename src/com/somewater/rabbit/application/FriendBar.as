package com.somewater.rabbit.application
{
	import com.somewater.control.IClear;
	import com.somewater.rabbit.storage.Config;
	import com.somewater.rabbit.storage.Lib;
	import com.somewater.rabbit.storage.UserProfile;
	
	import flash.display.DisplayObject;
	import flash.display.SimpleButton;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;

	public class FriendBar extends Sprite implements IClear
	{
		public static const WIDTH:int = 510;
		public static const HEIGHT:int = 120;
		public static const ITEMS:int = 4;

		private static var lastCommonPosition:int = 0;
		
		private var ground:DisplayObject;
		private var leftArrow:SimpleButton;
		private var leftStuporArrow:SimpleButton;
		private var rightArrow:SimpleButton;
		private var rightStuporArrow:SimpleButton;
		
		private var friendIcons:Array = [];
		private var friends:Array;
		private var _position:int = -1;
		
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
			rightArrow.x = 486;
			rightArrow.y = 25;
			addChild(rightArrow);
			
			rightStuporArrow = Lib.createMC("interface.ArrowStuporButton");
			rightStuporArrow.addEventListener(MouseEvent.CLICK, onArrowClick);
			rightStuporArrow.scaleX = -1;
			rightStuporArrow.x = 486;
			rightStuporArrow.y = 72;
			addChild(rightStuporArrow);
			
			friends = UserProfile.instance.appFriends.slice();
			friends.push(ImaginaryGameUser.instance)
			friends.sortOn("levelNumber", Array.NUMERIC | Array.DESCENDING);
			
			for(var i:int = 0;i<=ITEMS;i++)
			{
				var friendIcon:FriendIcon = new FriendIcon();
				friendIcon.x = 55 + i * 80;     
				friendIcon.y = 27;
				addChild(friendIcon);
				friendIcons.push(friendIcon);
			}
			position = lastCommonPosition;
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
		}
		
		public function set position(value:int):void
		{
			value = Math.max(0, Math.min(friends.length - ITEMS, value));
			if(value != _position)
			{
				lastCommonPosition = _position = value;
				for(var i:int = 0;i<ITEMS;i++)
				{
					var friendIcon:FriendIcon = friendIcons[i];
					friendIcon.setUser(friends[i + _position]);
				}
				
				var friendsMore:Boolean = friends.length > ITEMS;
				setButtonEnable(leftArrow, friendsMore  && _position > 0);
				setButtonEnable(leftStuporArrow, friendsMore && _position > 0);
				setButtonEnable(rightArrow, friendsMore && _position < friends.length - ITEMS);
				setButtonEnable(rightStuporArrow, friendsMore && _position < friends.length - ITEMS);
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
				value = -ITEMS;
			else if(arrow == leftStuporArrow)
				value = -100000;
			if(arrow == rightArrow)
				value = ITEMS;
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
	}
}