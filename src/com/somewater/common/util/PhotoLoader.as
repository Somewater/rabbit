package com.somewater.common.util
{
	import com.somewater.common.GameObject;
	import com.somewater.common.factory.McFactory;
	import com.somewater.common.managers.ModifyManager;
	import com.somewater.social.SocialUser;
	
	import flash.display.Bitmap;
	import flash.display.DisplayObject;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.geom.Rectangle;

	public class PhotoLoader extends GameObject {
		
		protected var user : SocialUser;
		protected var photo : DisplayObject;		
		protected var _photoAdded : Boolean = false;
		protected var preloadAnimation	: MovieClip;
		protected var noPhoto			: Sprite;
		protected var layoutContainer	: Sprite;
		protected var picMask : Sprite;
		
		protected var _loading : Boolean = false;
		
		public function PhotoLoader(container:MovieClip) {
			super(container);
			hasChildrenAge = true;
			this.user = user;
			preloadAnimation = McFactory.createMc('PreloadAnimation', 'ui') as MovieClip;			
			noPhoto = McFactory.createMc('NoPhoto', 'ui') as Sprite;
			picMask = container.getChildByName('picMask') as Sprite;
			layoutContainer = container.getChildByName('friendPicContainer') as Sprite;
		}
		
		public function loadUserPic(user : SocialUser) : void {
			this.user = user;
			_loading = true;
			ModifyManager.addChildInCenter(preloadAnimation, mc);
		}

		override public function tick(arg1:int=0):void {
			super.tick(arg1);
			if(_loading) {
				var p : Bitmap = user.mediumPhoto;
				if(p != null && !_photoAdded) {
					if(p.bitmapData != null) {
						photo = p;
						addPhoto(p);
					} else {
						addPhoto(noPhoto);
					}
				} 
			}
 		}
		
		public function addPhoto(bmp : DisplayObject) : void {
			photo = bmp;
			removePhoto();
			var obj : DisplayObject;
			obj = bmp;
			
			obj.scaleX = 1;
        	obj.scaleY = 1;
        	obj.x = layoutContainer.x;
        	obj.y = layoutContainer.y;
			ModifyManager.resizeImage(obj, layoutContainer);
			mc.addChild(obj);
			
//			obj.scrollRect = picMask.scrollRect;
			obj.mask = picMask;
			
//			_photoAdded = true;
			if(preloadAnimation && mc.contains(preloadAnimation)) {
				mc.removeChild(preloadAnimation);
			} 
			_loading = false;
		}
		
		public function removePhoto() : void {
			if(photo && mc.contains(photo)) {
				mc.removeChild(photo);
				photo.mask = null;
				photo = null;
			}
			_loading = false;
			if(preloadAnimation && mc.contains(preloadAnimation)) {
				mc.removeChild(preloadAnimation);
			}
			if(noPhoto && mc.contains(noPhoto)) {
				mc.removeChild(noPhoto);
			}
		}
	}
}