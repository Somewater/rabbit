package com.somewater.rabbit.application.map {
	import com.somewater.control.IClear;
	import com.somewater.display.Photo;
	import com.somewater.rabbit.storage.GameUser;
	import com.somewater.rabbit.storage.Lib;
	import com.somewater.text.Hint;

	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.filters.DropShadowFilter;

	public class MapFriendIcon extends Sprite implements IClear{

		protected var core:MovieClip;
		protected var photo:Photo;
		public var friend:GameUser;

		public function MapFriendIcon(friend:GameUser) {
			this.friend = friend;

			core = Lib.createMC('interface.MapFriendIcon');
			addChild(core);

			photo = new Photo(null, Photo.ORIENTED_CENTER | Photo.SIZE_MAX);
			photo.animatedShowing = false;
			photo.photoMask = core.photoMask;
			photo.source = friend.socialUser.photoSmall;
			buttonMode = useHandCursor = true;

			Hint.bind(this, friend.socialUser.name)

			filters = [new DropShadowFilter(2, 45, 0, 0.5, 10, 10)];
		}

		public function clear():void {
			photo.clear();
			Hint.removeHint(this)
		}
	}
}
