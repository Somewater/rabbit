package com.somewater.rabbit.application {
	import com.somewater.control.IClear;
	import com.somewater.display.CorrectSizeDefinerSprite;
	import com.somewater.rabbit.storage.GameUser;
	import com.somewater.rabbit.storage.Lib;
	import com.somewater.social.SocialUser;

	import flash.display.DisplayObject;
	import flash.display.Graphics;

	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.filters.DropShadowFilter;

	public class UsersSelector extends Sprite implements IClear{

		private var _selected:Array = [];
		private var _width:int = 300;
		private var _height:int = 200;

		private var ground:Sprite;
		private var icons:Array = [];
		private var iconsByUid:Object = {};
		private var scroller:RScroller;
		private var iconsHolder:Sprite;

		public function UsersSelector(users:Array) {
			users = users.slice();
			for(var i:int = 0;i < users.length; i++){
				if(users[i] is  GameUser){
					users[i] = GameUser(users[i]).socialUser;
				}
			}
			users.sort(sortFunction);

			ground = new Sprite();
			ground.filters = [new DropShadowFilter(0, 0, 0, 1, 10, 10, 0.3)];
			addChild(ground);

			iconsHolder = new CorrectSizeDefinerSprite();
			scroller = new RScroller();
			scroller.content = iconsHolder;
			addChild(scroller);

			for each(var u:SocialUser in users){
				var icon:UserItem = new UserItem(u);
				icons.push(icon);
				iconsByUid[u.id] = icon;
				iconsHolder.addChild(icon);
				icon.addEventListener(MouseEvent.CLICK, onIconClicked);
			}

			resize();
		}

		protected function sortFunction(a:SocialUser, b:SocialUser):int {
			// впереди не app-друзья
			if(a.isAppFriend && !b.isAppFriend)
				return 1;
			else if(!a.isAppFriend && b.isAppFriend)
				return -1;

			return a.lastName < b.lastName ? -1 : 1;
		}

		public function clear():void {
			for each(var u:UserItem in  icons){
				u.clear();
				u.removeEventListener(MouseEvent.CLICK, onIconClicked);
			}
		}

		public function get selected():Array {
			return _selected.slice();
		}

		public function set selected(values:Array):void {
			_selected = values.slice();
			var selectedUids:Object = {};
			for each(var s:SocialUser in _selected)
				selectedUids[s.id] = true;
			for each(var i:UserItem in icons){
				i.selected = selectedUids[i.user.id];
			}
			dispatchEvent(new Event(Event.CHANGE))
		}

		public function setSize(w:int, h:int):void {
			_width = w;
			_height = h;
			resize();
		}

		override public function get width():Number {
			return _width;
		}

		override public function get height():Number {
			return _height;
		}

		protected function resize():void {
			scroller.setSize(_width - 3, _height);
			var g:Graphics = ground.graphics;
			g.clear();
			g.beginFill(0xdef781);
			g.drawRoundRectComplex(0, 0, _width, _height, 8,8,8,8);

			var l:int = icons.length;
			var activeWidth:int = _width - RScroller.SCROLL_WIDTH - 15 - 3;
			var iconsByRow:int = (activeWidth - 10) / UserItem.WIDTH;
			var wGap:int = (activeWidth - iconsByRow * UserItem.WIDTH) / Math.max(1, iconsByRow - 1)
			var hGap:int = Math.min(wGap, 20);
			for(var i:int = 0; i < l; i++){
				var icon:UserItem = icons[i];
				icon.x = (i % iconsByRow) * (wGap + UserItem.WIDTH) + 10;
				icon.y = int(i / iconsByRow) * (hGap + UserItem.HEIGHT) + 10;
			}
		}

		private function onIconClicked(event:Event):void {
			var icon:UserItem = event.currentTarget as UserItem;
			if(icon.selected){
			   var oldSelected:Array = this.selected;
				for (var i:int = 0; i < oldSelected.length; i++) {
					var s:SocialUser = oldSelected[i];
					if(s == icon.user){
						oldSelected.splice(i, 1);
						this.selected = oldSelected;
						break;
					}
				}
			} else {
				selected = selected.concat([icon.user]);
			}
		}

		public function scrollToSelected():void {
			if(selected.length == 1){
				var s:SocialUser = selected[0];
				var icon:UserItem;
				for each(var i:UserItem in icons)
					if(i.user == s) {
						icon = i;
						break;
					}
				if(icon){
					var icony:int = icon.y;
					if(icony > UserItem.HEIGHT){
						if(icony > iconsHolder.height - UserItem.HEIGHT)
							icony = iconsHolder.height;
						else
							icony -= UserItem.HEIGHT;
					}
					scroller.position = icony == 0 ? 0 : icony / iconsHolder.height;
				}
			}
		}
	}
}

import com.somewater.control.IClear;
import com.somewater.display.Photo;
import com.somewater.rabbit.application.buttons.InteractiveOpaqueBack;
import com.somewater.rabbit.storage.Config;
import com.somewater.rabbit.storage.Lib;
import com.somewater.social.SocialUser;
import com.somewater.text.EmbededTextField;

import flash.display.Sprite;
import flash.events.MouseEvent;
import flash.text.TextFieldAutoSize;

class UserItem extends Sprite implements IClear{

	public static const WIDTH:int = 160;
	public static const HEIGHT:int = 70;

	public var user:SocialUser;

	private var photoSprite:Sprite;
	private var photo:Photo;
	private var nameTF:EmbededTextField;
	private var ground:InteractiveOpaqueBack;

	private var _selected:Boolean = false;

	public function UserItem(user:SocialUser){
		this.user = user;

		ground = new InteractiveOpaqueBack();
		ground.setSize(WIDTH, HEIGHT);
		addChild(ground);

		photoSprite = Lib.createMC('interface.TopUserPhoto');
		photo = new Photo();
		photo.photoMask = photoSprite.getChildByName('photoMask');
		photoSprite.x = 10;
		photoSprite.y = 9;
		addChild(photoSprite);
		nameTF = new EmbededTextField(Config.FONT_SECONDARY, 0x124D18, 12);
		nameTF.multiline = true;
		nameTF.autoSize = TextFieldAutoSize.LEFT
		nameTF.x = photoSprite.x + photoSprite.width + 10;
		nameTF.y = photoSprite.y;
		nameTF.text = '---\n---'
		nameTF.width = WIDTH - nameTF.x - 10;
		addChild(nameTF);

		nameTF.text = user.firstName + '\n' + user.lastName;
		photo.source = user.photoSmall;

		_selected = true;
		selected = false;
	}

	public function clear():void {
		photo.clear();
		ground.clear();
	}

	public function get selected():Boolean {
		return _selected;
	}

	public function set selected(value:Boolean):void {
		if(_selected != value){
			_selected = value;
			nameTF.color = value ? 0xFFFFFF : 0x124D18;
			ground.alpha = value ? 1 : 0.2;
		}
	}
}